import argparse
import subprocess

from plist import to_plist

import xml.etree.ElementTree as ET

from machines import MACHINES, SLOTS

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
		"floppy_5_25": "flop_5_25",
		"floppy_3_5": "flop_3_5",
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

			# format slot name : slotoption name : machine->device type name

		if mname == "apple2c" and slot == "sl6": slot = None

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
		"floppy_apple": "flop_5_25",
		"harddisk_image": "hard",
		"floppy_sonny": "flop_3_5",
	}
	remap_slot = {
		"harddisk": "hard",
		"hdd": "hard",
		"cdrom": "cdrm",
		"525": "flop_5_25",
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
		media.get["flop_5_25"] = media.get("flop_5_25", 0) + 2

	if not media: return None
	return media

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
	tmp = [
		{
			"intValue": int(x.text),
			"description": x.get("name"),
			"value": x.get("name"),
			"default": x.get("default") == "yes"
		}
		for x in machine.findall('ramoption')
	]
	# sort and add empty starting entry.
	tmp.sort(key=lambda x: x["intValue"])
	# tmp.insert(0, {"value": 0, "default": False, "description": "" })
	data["ram"] = tmp


	data["media"] = find_machine_media(machine)


	# node = machine.find('display[@tag="screen"]')
	node = machine.find('./display')
	data["resolution"] = [int(node.get("width")), int(node.get("height")) * 2]

	mm = {}
	for x in root.findall("machine[@isdevice='yes']"):
		name = x.get("name")
		mm[name] = x # .find("description").text
		# also need to find media...

	# print(mm)

	# ss = {}
	for s in SLOTS:
		path = 'slot[@name="{}"]/slotoption'.format(s)
		nodes = machine.findall(path)
		if not nodes: continue

		tmp = []
		has_default = False
		for x in nodes:
			name = x.get("name")
			devname = x.get("devname")
			desc = mm[devname].find("description").text
			default = x.get("default") == "yes"
			disabled = name in DISABLED

			d = { "value": name, "description": desc, "default": default }
			if disabled: d["disabled"] = True
			else:
				media = find_media(mm[devname], True)
				if media: d["media"] = media
			tmp.append(d)
			has_default |= default

		tmp.sort(key=lambda x: x["description"].upper() )
		tmp.insert(0, {"value": "", "description": "—None—", "default": not has_default})
		data[s] = tmp


	path = "../Ample/Resources/{}.plist".format(m)
	with open(path, "w") as f:
		f.write(to_plist(data))



