
import subprocess

from plist import to_plist

import xml.etree.ElementTree as ET

from machines import MACHINES


devices = {}

for m in MACHINES:


	st = subprocess.run(["mame", m, "-listxml"], capture_output=True)
	if st.returncode != 0:
		print("mame error: {}".format(m))
		exit(1)

	xml = st.stdout
	root = ET.fromstring(xml)

	nodes = root.findall("machine[@isdevice='yes']")
	for d in nodes:

		name = d.get("name") # devname
		desc = d.find("description").text

		tmp = {
			"Name": name,
			"Description": desc
		}
		devices[name] = tmp


with open("../Ample/Resources/devices.plist", "w") as f:
	f.write(to_plist(devices))
