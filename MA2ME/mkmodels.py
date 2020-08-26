import subprocess

from plist import to_plist

import xml.etree.ElementTree as ET

from machines import MACHINES

import re

apple1_children = None
apple2_children = ["apple2", "apple2p", "apple2jp"]
apple3_children = None
apple2e_children = ["apple2e", "apple2ees", "apple2euk", "apple2ep", "apple2ee", "apple2eeuk", "apple2eefr"]
apple2c_children = ["apple2c", "apple2cp"]
apple2gs_children = ["apple2gsr0", "apple2gsr1", "apple2gs"]
laser_children = ["laser128", "laser2c", "las128ex", "las128e2"]
ii_clones_children = ["ace100", "agat7", "agat9", "albert",
	"am100", "am64", "basis108", "craft2p",
	"dodo", "elppa", "hkc8800a", "ivelultr",
	"maxxi", "microeng", "prav82", "prav8m",
	"space84", "uniap2en", "uniap2pt", "uniap2ti"]
iie_clones_children = ["mprof3", "prav8c", "spectred"]

tree = [
	("Apple I", "apple1", apple1_children),
	("Apple ][", "apple2", apple2_children),
	("Apple IIe", "apple2e", apple2e_children),
	("Apple //c", "apple2c", apple2c_children),
	("Apple IIgs", "apple2gs", apple2gs_children),
	("Apple ///", "apple3", apple3_children),
	("Laser", "laser128", laser_children),
	("II Clones", None, ii_clones_children),
	("IIe Clones", None, iie_clones_children),
]

st = subprocess.run(["mame", "-listfull", *MACHINES], check=True, capture_output=True, text=True)
# Name:             Description:
# apple2gs          "Apple IIgs (ROM03)"
# apple2gsr0        "Apple IIgs (ROM00)"

names = {}

t = st.stdout
lines = t.split("\n")
lines.pop(0)
for x in lines:
	x = x.strip()
	if x == "": continue
	m = re.fullmatch(r"^([A-Za-z0-9_]+)\s+\"([^\"]+)\"$", x)
	if not m:
		print("hmmm....", x)
		continue
	name = m[1]
	desc = m[2]

	names[name] = desc


def make_children(clist):
	global names
	return [
		{ "description": names[x], "value": x}
		for x in clist
	]

data = []

for x in tree:
	desc, value, children = x
	tmp = { "description": desc }
	if value: tmp["value"] = value
	if children: tmp["children"] = make_children(children)

	data.append(tmp)

path = "Resources/models.plist"
with open(path, "w") as f:
	f.write(to_plist(data))

