import argparse
import hashlib

from copy import deepcopy
from plist import to_plist

import xml.etree.ElementTree as ET

from machines import MACHINES, MACHINES_EXTRA, SLOTS, SLOT_NAMES
import mame

# macintosh errata:
# maclc has scsi:1 - scsi:7 and lcpds slots, but none are currently configurable.
# maciifx has scsi:1 - scsi:7 (not configurable)
# maciifx has "nb9",  "nba" - "nbe" as configurable nubus slots
#
# w/ nubus, can specify video card which may have different resolution.
#
# Inside Macintosh: Devices chapter 2 explains the Nubus slot name scheme
# (essentially $01-$0e; $0 and $f are reserved)
#
# TODO -printout

#
# SCSI devices:
# ROM 1, a2scsi, golden orchard, as of 239 wip:
# cdrom - CDROM
# aplcdsc - Apple SCSI CDROM
#
# these are all skeleton drivers and generally require a ROM.
#
# aplcd150 - Apple CD 150 - bad dump, known problems warning, shows in finder as hard drive
# cdrn820s - Caravell CDR-N820s - shows in finder as hard drive
# cfp1080s - known problems warning, shows as hard drive
# cdr4210 - known problems warning, shows as hard drive
# cw7501 - known problems warning, shows as hard drive
# cdd2000 - known problems warning, shows as hard drive
# crd254sh - known problems warning, shows as hard drive
# cdu415 - known problems warning, shows as hard drive
# cdu561_25 - known problems warning, shows as hard drive
# smoc501 - known problems warning, shows as hard drive
# cdu75s - known problems warning, shows as hard drive
#
#


# don't allow these for now. generally because they add floppy/hard drives
# but don't work with normal disk images
DISABLED = set((
	'pcxport',
	'hsscsi', # doesn't work
	'corvus', # these apparently don't use normal disk images.
	'zipdrive',
	'focusdrive',
	'vulcan',
	'vulcangold',
	'vulcaniie',
	'sider',
	'xebec',
	'sider1',
	'sider2',
	'cmsscsi',
	('apple2gs', 'cffa202'),
	('apple2gsr0', 'cffa202'),
	('apple2gsr1', 'cffa202'),
))



machine_cache = {}
submachines = {} # with slots.


def load_machine(name):

	rootname = name
	if name in machine_cache: return machine_cache[name]

	xml = mame.run(name, "-listxml")
	root = ET.fromstring(xml)

	for x in root.findall("./machine"):
		name = x.get("name")
		if name in machine_cache: continue
		machine_cache[name] = x

	return machine_cache[rootname]


def load_machine_recursive(name):
	# machine_cache.clear()
	submachines.clear()

	rootname = name
	m = load_machine(name)
	if not m: return None

	processed = set()
	pending = { rootname }
	while pending:

		name = pending.pop()
		m = load_machine(name)
		processed.add(name)
		if not m:
			print("    *{}".format(name))
			continue
		count = 0
		for x in m.findall('./slot/slotoption'):
			count = count+1
			devname = x.get('devname')
			if devname in processed: continue
			pending.add(devname)

		if count:
			# print("    slots: {}".format(name))
			submachines[name] = m


	if rootname in submachines:
		del submachines[rootname]

	return machine_cache[rootname]


def find_machine_media(parent):
	# look for relevant device nodes.  If the tag contains a slot, skip since it's
	# not built in. Except the Apple3, where the floppy drives are actually slots 0/1/2/3/4
	#
	# apple1 has a "snapshot" device.  not currently supported.
	# mac fpds slot - not supported
	# mac128 kbd slot - not supported
	# in the //c (but not //c+) the floppy drives are in slot 6 which doesn't otherwise exist.
	#
	# not supported:
	# apple1 - snapshot device
	# mac [various] - pds/lcpds slot
	# mac128k - kbd slot
	#
	# mac - if scsi:3 / scsibus:3 are not in the xml but are hardcoded cd-rom drives.


	mname = parent.get("name")
	remap = {
		"cassette": "cass",
		"apple1_cass": "cass",
		"apple2_cass": "cass",
		"floppy_5_25": "floppy_5_25",
		"floppy_3_5": "floppy_3_5",
		# mac
		"scsi_hdd": "hard",
		"cdrom": "cdrom",
	}
	media = {}
	for x in parent.findall("./device"):
		tag = x.get("tag")
		typ = x.get("type")
		intf = x.get("interface")
		if intf == None: intf = typ # cassette has no interface.

		# print("  ",intf)

		slot = None
		if ':' in tag:
			tt = tag.split(':')
			slot = tt[0]

		# hack for now - these are scsi:1-7 slots but slot option isn't adjustable.
		# as of 232 (231?), these are configurable as :scsi:0, etc or :scsibus:0, etc.
		# if mname[0:3] == "mac" and slot in ("scsi", "scsibus"): slot = None

		# MAME 0.258 - scsi slot 3 now hardcoded for cd-rom
		if slot and intf != "cdrom": continue
		# skip slot devices -- they'll be handled as part of the device.

		if intf in remap:
			name = remap[intf]
			media[name] = media.get(name, 0) + 1

	return media



def find_media(parent, include_slots=False):

	# not strictly correct since they could have different extensions.


	# built-in devices (cassette_image, floppy_sonny, floppy_apple) and default slots
	# have a top-level <device> node which includes the name and extensions.


	# slot media generally has a <device> node inline (corvus, diskii)
	# -or-
	# slot/slotoption default="yes", devname is a machine with a device node.
	# diskiing is an exception, naturally.

	# this ignores the above.


	remap_dev = {
		"cassette_image": "cass",
		"floppy_apple": "floppy_5_25",
		"harddisk_image": "hard",
		"floppy_sonny": "floppy_3_5",
		"messimg_disk_image": "pseudo_disk",
		"bitbanger": "bitbanger", # null_modem, etc.
		"picture_image": "picture", # a2ceyes
		# "printer_image": "printout",
		"midiin": "midiin",
		"midiout": "midiout",
	}
	remap_slot = {
		# now handled at the slot level.
		# "harddisk": "hard",
		# "hdd": "hard",
		# "cdrom": "cdrom",
		# "525": "floppy_5_25",
		"image": "psuedo_disk",
	}

	media = {}
	# floppies
	for x in parent.findall("./device_ref"):
		name = x.get("name")
		if name in remap_dev:
			name = remap_dev[name]
			media[name] = media.get(name, 0) + 1

		# ata_slot (vulcan, cffa, zip, etc) needs to check slot to see if default.
		# nscsi_connector (a2scsi, a2hsscsi) needs to check slot to see if default.

	# a2scsi - has 6 slots each with an option to be a cdrom or hard disk.
	# default is 1 cdrom, 1 hard disk.
	# could use -sl6:scsi:scsibus:6 harddisk|cdrom to explicitly set them.
	# this would, of course, screw up the device counting logic.

	# focus/vulcan can also enable a second harddisk/cdrom.

	if not include_slots: return media

	for x in parent.findall("./slot/slotoption"):
		if x.get("default") != "yes": continue
		name = x.get("name")
		if name in remap_slot:
			name = remap_slot[name]
			media[name] = media.get(name, 0) + 1


	# special case for the pc transporter.  not in the xml but it adds 2 5.25" floppies
	# n.b. - floppies are 5.25" 360k or 180k.  not bootable, not usable from prodos
	# without special prodos file or loading driver into pc transporter ram.
	if parent.get("name") == "pcxport":
		media["floppy_5_25"] = media.get("floppy_5_25", 0) + 2


	# special case for a2romusr
	if parent.get("name") == "a2romusr":
		media["rom"] = media.get("rom", 0) + 1

	# scsibus:1 is special cd-rom
	if parent.get("name") == "a2scsi":
		media["cdrom"] = media.get("cdrom", 0) + 1

	if not media: return None
	return media


def one_software(x):
	xml = x.get("name") + ".xml"
	filter = x.get("filter")
	if filter: return { "name": xml, "filter": filter }
	return xml

def find_software(parent):
	swl = parent.findall("./softwarelist")
	return [one_software(x) for x in swl]



DEVICE_REMAP = {
	'cdrom': 'CD-ROM',
	'hdd': 'Hard Disk',
	'harddisk': 'Hard Disk',
	"525": '5.25"',
	'35hd': '3.5" HD',
	'35dd': '3.5" DD',
	'35sd': '3.5" SD',
	'a2romusr': 'ROM',
}
DEVICE_MEDIA = {
	'cdrom': 'cdrom',
	'hdd': 'hard',
	'harddisk': 'hard',
	'525': 'floppy_5_25',
	'35hd': 'floppy_3_5',
	'35dd': 'floppy_3_5',
	'35sd': 'floppy_3_5',
	'midiin': 'midiin',
	'midiout': 'midiout',
	'aplcdsc': 'cdrom',
	# 'null_modem': 'bitbanger',
	# 'rs232_sync_io': 'bitbanger',
	'a2romusr': 'rom',
}

DEVICE_EXCLUDE = set([
	# cd drives, etc.
	'aplcd150',
	'cdd2000',
	'cdr4210',
	'cdrn820s',
	'cdu415',
	'cdu561_25',
	'cdu75s',
	'crd254sh',
	'cw7501',
	'px320a',
	's1410',
	'smoc501',
	'cfp1080s',
	'cf', # ATA compact flash
	'cp2024', # Conner Peripherals CP-2024 hard disk
])

def make_device_options(slot):
#
# As of MAME .258 ---
# apple 2 scsi slot 1 is a default cd rom device.
# Macintosh scsi slot 3 is a default cd rom device.
# THIS IS NOT REFLECTED IN THE XML SINCE IT'S SET AT RUN TIME.
# IN FACT, THE :scsi

	options = []
	has_default = False
	#has_media = False
	for option in slot.findall("./slotoption"):
		name = option.get("name")
		devname = option.get("devname")

		if name in DEVICE_EXCLUDE: continue

		device = None
		if devname in machine_cache: device = machine_cache[devname]
		if name in DEVICE_REMAP:
			desc = DEVICE_REMAP[name]
		elif device:
			desc = device.find("description").text
		else:
			# print("{} - {}".format(name, devname))
			continue

		default = option.get("default") == "yes"
		has_default |= default
		media = None

		if name in DEVICE_MEDIA: media = { DEVICE_MEDIA[name]: 1 }
		elif device and device.find("./device_ref[@name='bitbanger']") != None: media = { 'bitbanger': 1 }
		elif device and device.find("./device_ref[@name='picture_image']") != None: media = { 'picture': 1 }
		# elif device and device.find("./device_ref[@name='printer_image']") != None: media = { 'printout': 1 }


		# if name == "cdrom":
		# 	print("{} - {} - {}".format(slot.get('name'), name, devname))
		# 	print(option)
		# 	if slot.get('name') == ':scsibus:1':
		# 		default = True
		# 		has_default = True

		item = {
			'value': name,
			'description': desc,
			'default': default
		}
		if media: item['media'] = media
		options.append(item);

	if not options: return None
	options.sort(key=lambda x: x["description"].upper() )
	options.insert(0, {"value": "", "description": "—None—", "default": not has_default})

	return options


	# given a machine, return a list of slotoptions.
def make_device_slots(machine):

	mname = machine.get('name')

	# add missing cd-rom scsi slot1
	# s0 = machine.find('./slot[@name=":scsibus:0"]')
	# s1 = machine.find('./slot[@name=":scsibus:1"]')
	# if s0 and not s1:
	# 	s1 = deepcopy(s0)
	# 	s1.set('name', ':scsibus:1')
	# 	s1.find('slotoption[@name="cdrom"]').set('default','yes')
	# 	for ix in range(0, len(machine)):
	# 		if machine[ix] == s0:
	# 			machine.insert(ix+1, s1)
	# 			break
	# 	#machine.insert(5,s1)



	slots = []
	for slot in machine.findall('./slot'):
		slotname = slot.get("name")
		options = make_device_options(slot)
		if not options: continue
		slots.append({
			"name": slotname,
			"options": options
		})

	if not len(slots): return None

	return slots

def make_devices():
	
	devices = []
	# alphabetically so it doesn't change.
	names = list(submachines.keys())
	names.sort()

	for name in names:
		m = submachines[name]
		slots = make_device_slots(m)
		if slots:
			devices.append({
				"name": name,
				"slots": slots
			})
	return devices




def make_ram(machine):

	options = [
		{
			"intValue": int(x.text),
			"description": x.get("name"),
			"value": x.get("name"),
			"default": x.get("default") == "yes"
		}
		for x in machine.findall('ramoption')
	]

	# special case for laser 3000....
	if len(options) == 0 and machine.get('name') == 'las3000':
		options.append( { "intValue": 192, "description": "192K", "value": "192K", "default": True} )

	if not options: return None

	# sort and add empty starting entry.
	options.sort(key=lambda x: x["intValue"])

	return {
		"name": "ramsize",
		"description": SLOT_NAMES["ramsize"],
		"options": options
	}



def make_bios(m):

	options = [
		{
			"value": x.get("name"),
			"description": x.get("description")
		}
		for x in m.findall('./biosset')
	]

	if not options: return None

	options.insert(0, {"value": "", "description": "—Default—", "default": True })

	return {
		"name": "bios",
		"description": SLOT_NAMES["bios"],
		"options": options
	}


def make_smartport(machine):


	# iigs: <slot name="fdc:0" .. "fdc:3">
	# iic: <slot name="sl6:0" .. "sl6:1">
	# apple 3: <slot name="0" .. "3">
	# apple 2: diskiing card
	# maclc <slot name="scsi:1" .. "scsi:7" (but 4-7 not configurable)
	# maciix <slot name="scsi:6">
	# macse <slot name="scsibus:6">
	# atari st, etc: <slot name="wd1772:[0-1]">

	slots = []
	SLOTS = [
		*['fdc:' + str(x) for x in range(0,4)],
		*['scsi:' + str(x) for x in range(0,7)],
		*['scsibus:' + str(x) for x in range(0,7)],
		*['wd1772:' + str(x) for x in range(0,4)],

		"sl6:0", "sl6:1", "0", "1", "2", "3"
	]

	# surgery to add cd-rom scsi nodes:
	# s2 = machine.find('slot[@name="scsi:2"]')
	# s3 = machine.find('slot[@name="scsi:3"]')
	# if s2 and not s3:
	# 	s3 = deepcopy(s2)
	# 	parent = s2.find("..")
	# 	# print(s2)
	# 	# print(parent)
	# 	s3.set('name', 'scsi:3')
	# 	s3.find('slotoption[@name="cdrom"]').set('default','yes')
	# 	machine.append(s3)
	# 	# print("inserting s3")

	# s2 = machine.find('slot[@name="scsibus:2"]')
	# s3 = machine.find('slot[@name="scsibus:3"]')
	# if s2 and not s3:
	# 	s3 = deepcopy(s2)
	# 	parent = s2.find("..")
	# 	s3.set('name', 'scsibus:3')
	# 	s3.find('slotoption[@name="cdrom"]').set('default','yes')
	# 	machine.append(s3)



	for s in SLOTS:
		path = 'slot[@name="{}"]'.format(s)
		slot = machine.find(path)
		if not slot: continue

		slotname = slot.get("name")
		options = make_device_options(slot)
		if not options: continue
		slots.append({
			"name": slotname,
			"options": options
		})

	if not slots: return None
	return {
		"name": "smartport",
		"slots": slots
	}

def fix_machine_description(x, devname):
	#
	x = x.replace(", www.dreher.net","")
	x = x.replace("))", ")") # Apple II ROM Card (Integer BASIC))
	return x

def make_slot(m, slotname, nodes):

	options = []

	has_default = False
	for x in nodes:
		name = x.get("name")
		devname = x.get("devname")
		desc = machine_cache[devname].find("description").text
		default = x.get("default") == "yes"
		disabled = name in DISABLED or (m, name) in DISABLED

		d = { "value": name, "description": fix_machine_description(desc, devname) } # "devname": devname or ''}
		if default: d["default"] = True
		if disabled: d["disabled"] = True
		if not disabled:
			d["devname"] = devname
			media = find_media(machine_cache[devname], True)
			if media:
				d["media"] = media


		options.append(d)
		has_default |= default


	options.sort(key=lambda x: x["description"].upper() )
	options.insert(0, {"value": "", "description": "—None—", "default": not has_default})

	return {
		"name": slotname,
		"description": SLOT_NAMES[slotname],
		"options": options
	}


def file_changed(path, data):
	# check if a file has changed.

	try:
		with open(path, mode='rb') as f:
			d1 = hashlib.file_digest(f, 'sha256')
	except Exception as e:
		return 'new'

	d2 = hashlib.sha256(bytes(data, 'utf8'))

	if d1.digest() == d2.digest(): return False
	return 'updated'



devices = {}

p = argparse.ArgumentParser()
p.add_argument('machine', nargs="*")
p.add_argument('--extra', action='store_true')
args = p.parse_args()

extra = args.extra
machines = args.machine
if not machines:
	if extra:
		machines = MACHINES_EXTRA
	else:
		machines = MACHINES

for m in machines:

	print(m)

	machine = load_machine_recursive(m)
	if not machine:
		exit(1)

	data = {  }


	# path = 'machine[@name="{}"]'.format(m)
	# machine = root.find(path)

	data["value"] = m
	data["description"] = machine.find("description").text

	data["media"] = find_machine_media(machine)


	# node = machine.find('display[@tag="screen"]')
	node = machine.find('./display')
	#print('display:', node.get('tag'))
	hscale = 2
	if m[0:3] == "mac": hscale = 1
	data["resolution"] = [int(node.get("width")), int(node.get("height")) * hscale]

	# submachines.clear()
	# for x in root.findall("machine[@isdevice='yes']"):
	# 	name = x.get("name")
	# 	submachines[name] = x # .find("description").text
	# 	# also need to find media...


	# ss = {}
	slots = []
	x = make_ram(machine)
	if x: slots.append(x)
	x = make_bios(machine)
	if x: slots.append(x)

	smartport = make_smartport(machine)
	if smartport:
		slots.append({
			"name": "smartport",
			"description": "Disk Drives",
			"options": [{
				"value": "",
				"description": "",
				"devname": "smartport",
				"default": True,
			}]
		})

	for s in SLOTS:
		path = 'slot[@name="{}"]/slotoption'.format(s)
		nodes = machine.findall(path)
		if not nodes: continue

		s = make_slot(m, s, nodes)
		slots.append(s);

	data["slots"] = slots

	devices = make_devices()
	if smartport: devices.insert(0, smartport)
	data["devices"] = devices
	data["software"] = find_software(machine)


	path = "../Ample/Resources/{}.plist".format(m)
	pl = to_plist(data)
	st = file_changed(path, pl)
	if st == False: continue
	print(m + ':', st)
	with open(path, "w") as f:
		f.write(pl)



