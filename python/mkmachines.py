import argparse
import subprocess

from plist import to_plist

import xml.etree.ElementTree as ET

from machines import MACHINES, SLOTS, SLOT_NAMES

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


def find_machine_media(parent):
	# look for relevant device nodes.  If the tag contains a slot, skip since it's
	# not built in. Except the Apple3, where the floppy drives are actually slots 0/1/2/3/4
	#
	# apple1 has a "snapshot" device.  not currently supported.
	#
	# in the //c (but not //c+) the floppy drives are in slot 6 which doesn't otherwise exist.
	#

	# no machines have built-in hard drives.

	mname = parent.get("name")
	remap = {
		"cassette": "cass",
		"apple1_cass": "cass",
		"apple2_cass": "cass",
		"floppy_5_25": "floppy_5_25",
		"floppy_3_5": "floppy_3_5",
		# mac
		"scsi_hdd": "hard",
		#"cdrom": "cdrom", -- 2021-01-18 - CD rom is more or less broken so exclude it.
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
			if len(tt) >= 3: slot = tt[0]
			# exclude:
			# apple1 - tag="exp:cassette:cassette"
			# apple2 - tag="sl6:diskiing:0:525" - <slot name="sl6">
			# include:
			# apple2c - tag="sl6:0:525"  - <slot name="sl:0">.
			# apple3 - tag="0:525" - <slot name="0">

			# .229 apple2gs:
			# <device type="floppydisk" tag="fdc:0:525" interface="floppy_5_25">
			# <device type="floppydisk" tag="fdc:2:35dd" interface="floppy_3_5">

			# format slot name : slotoption name : machine->device type name

		if mname == "apple2c" and slot == "sl6": slot = None
		if slot=="fdc": slot = None # .229 IIgs

		# hack for now - these are scsi:1-7 slots but slot option isn't adjustable.
		if mname[0:3] == "mac" and slot == "scsi": slot = None

		if slot: continue
		# skip slot devices -- they'll be handled as part of the device.
		#if ":" in tag and tag[0] not in "0123456789": continue

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
	}
	remap_slot = {
		# "harddisk": "hard",
		# "hdd": "hard",
		# "cdrom": "cdrom",
		"525": "floppy_5_25",
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
		media.get["floppy_5_25"] = media.get("floppy_5_25", 0) + 2

	if not media: return None
	return media


def find_software(parent):
	swl = parent.findall("./softwarelist")
	return [x.get("name") + ".xml" for x in swl]



	# given a machine, return a list of slotoptions.
def slot_options(machine):
	REMAP = {
		'cdrom': 'CD-ROM',
		'hdd': 'Hard Disk',
		'harddisk': 'Hard Disk',
		# "525": '5.25"'
		# '35hd': '3.5" HD',
		# '35dd': '3.5" DD',
		# '35sd': '3.5" SD',
	}
	MEDIA = {
		'cdrom': 'cdrom',
		'hdd': 'hard',
		'harddisk': 'hard',
	}

	mname = machine.get('name')

	slots = []
	for slot in machine.findall('./slot'):
		slotname = slot.get("name")
		options = []
		has_default = False
		#has_media = False
		for option in slot.findall("./slotoption"):
			name = option.get("name")
			if name not in REMAP: continue
			default = option.get("default") == "yes"
			has_default |= default
			options.append({
				'value': name,
				'description': REMAP[name],
				'media': { MEDIA[name]: 1 },
				'default': default
			})
		# n.b. 9 diskiing, for example, has media but only 2 options...
		# if len(options) < 2 : continue # don't bother if only 1 option which is going to be defaulted anyhow.
		if not options: continue
		options.sort(key=lambda x: x["description"].upper() )
		options.insert(0, {"value": "", "description": "—None—", "default": not has_default})

		slots.append({
			"name": slotname,
			"options": options
		})

	if not len(slots): return None

	return slots

def make_devices(mm):
	
	devices = []
	for m in mm.values():
		name = m.get("name")
		slots = slot_options(m)
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
	# sort and add empty starting entry.
	options.sort(key=lambda x: x["intValue"])

	return {
		"name": "ramsize",
		"description": SLOT_NAMES["ramsize"],
		"options": options
	}


def make_slot(m, slotname, nodes):

	options = []

	has_default = False
	for x in nodes:
		name = x.get("name")
		devname = x.get("devname")
		desc = mm[devname].find("description").text
		default = x.get("default") == "yes"
		disabled = name in DISABLED or (m, name) in DISABLED

		d = { "value": name, "description": desc } # "devname": devname or ''}
		if default: d["default"] = True
		if disabled: d["disabled"] = True
		if not disabled:
			d["devname"] = devname
			media = find_media(mm[devname], True)
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



devices = {}

p = argparse.ArgumentParser()
p.add_argument('machine', nargs="*")
args = p.parse_args()

machines = args.machine
if not machines: machines = MACHINES

for m in machines:

	print(m)

	env = {'DYLD_FALLBACK_FRAMEWORK_PATH': '../embedded'}
	st = subprocess.run(["../embedded/mame64", m, "-listxml"], capture_output=True, env=env)
	if st.returncode != 0:
		print("mame error: {}".format(m))
		exit(1)

	data = {  }

	xml = st.stdout
	root = ET.fromstring(xml)

	path = 'machine[@name="{}"]'.format(m)
	machine = root.find(path)

	data["value"] = m
	data["description"] = machine.find("description").text

	data["media"] = find_machine_media(machine)


	# node = machine.find('display[@tag="screen"]')
	node = machine.find('./display')
	hscale = 2
	if m[0:3] == "mac": hscale = 1
	data["resolution"] = [int(node.get("width")), int(node.get("height")) * hscale]

	mm = {}
	for x in root.findall("machine[@isdevice='yes']"):
		name = x.get("name")
		mm[name] = x # .find("description").text
		# also need to find media...

	# print(mm)

	# ss = {}
	slots = []
	slots.append(make_ram(machine))
	for s in SLOTS:
		path = 'slot[@name="{}"]/slotoption'.format(s)
		nodes = machine.findall(path)
		if not nodes: continue

		s = make_slot(m, s, nodes)
		slots.append(s);

	data["slots"] = slots

	data["devices"] = make_devices(mm)
	data["software"] = find_software(machine)


	path = "../Ample/Resources/{}.plist".format(m)
	with open(path, "w") as f:
		f.write(to_plist(data))



