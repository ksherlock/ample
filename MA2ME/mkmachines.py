
import subprocess

from plist import to_plist

import xml.etree.ElementTree as ET

from machines import MACHINES, SLOTS

devices = {}

for m in MACHINES:

	print(m)

	st = subprocess.run(["mame", m, "-listxml"], capture_output=True)
	if st.returncode != 0:
		print("mame error: {}".format(m))
		exit(1)

	d = {  }

	xml = st.stdout
	root = ET.fromstring(xml)

	path = 'machine[@name="{}"]'.format(m)
	machine = root.find(path)

	d["value"] = m
	d["description"] = machine.find("description").text
	d["RAM"] = [
		{
			"value": int(x.text),
			"description": x.get("name")
		}
		for x in machine.findall('ramoption')
	]

	node = machine.find('display[@tag="screen"]')
	d["Resolution"] = [int(node.get("width")), int(node.get("height")) * 2]

	mm = {}
	for x in root.findall("machine[@isdevice='yes']"):
		name = x.get("name")
		mm[name] = x.find("description").text

	# print(mm)

	# ss = {}
	for s in SLOTS:
		path = 'slot[@name="{}"]/slotoption'.format(s)
		nodes = machine.findall(path)
		if not nodes: continue

		tmp = []
		for x in nodes:
			name = x.get("name")
			devname = x.get("devname")
			desc = mm[devname]
			tmp.append({ "value": name, "description": desc })
		d[s] = tmp
		# d[s] = [(x.get("name"), x.get("devname")) for x in nodes]

	# d["Slots"] = ss


	path = "Resources/{}.plist".format(m)
	with open(path, "w") as f:
		f.write(to_plist(d))



