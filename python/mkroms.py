import argparse
import subprocess

from plist import to_plist

import xml.etree.ElementTree as ET

from machines import MACHINES



# a2pcxport dependencies. not automatically included though
# (would need to manually pull devnames from a2pcxport then)
# listxml for them.

EXTRA_MACHINES = [
	'vgmplay',
	'cga',
	'kb_iskr1030',
	'kb_ec1841',
	'kb_pc83',
	'kb_pcxt83',
	'keytronic_pc3270',
	'apple2gsr0p',
	'apple2gsr0p2',
	'apple2c0',
	'apple2c3',
	'apple2c4',
]


p = argparse.ArgumentParser()
p.add_argument('--full', action='store_true')
p.add_argument('machine', nargs="*")
args = p.parse_args()

full = args.full
machines = args.machine
if not machines: machines = [ *MACHINES, *EXTRA_MACHINES]

# roms stored in other files.
EXCLUDE = [
	'ace100',
	'agat7',
	'agat9',
	'albert',
	'am100',
	'am64',
	'apple2cp',
	'apple2ee',
	'apple2eefr',
	'apple2ees',
	'apple2eeuk',
	'apple2ep',
	'apple2euk',
	'apple2gsr0',
	'apple2gsr1',
	'apple2jp',
	'apple2p',
	'basis108',
	'craft2p',
	'dodo',
	'elppa',
	'hkc8800a',
	'ivelultr',
	'las128e2',
	'las128ex',
	'laser128',
	'laser2c',
	'maxxi',
	'microeng',
	'mprof3',
	'prav82',
	'prav8c',
	'prav8m',
	'space84',
	'spectred',
	'uniap2en',
	'uniap2pt',
	'uniap2ti',
]


mnames = set()
rnames = set()
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

	# find machines that have a rom child
	for x in root.findall('machine/rom/..'):
		mnames.add(x.get('name'))
		for y in x.findall('./rom'):
			rnames.add(y.get('name'))
		

# print("\n\n\n")
# ll = list(mnames.difference(EXCLUDE))
# ll.sort()
# for x in ll:
# 	print(x)

if full: ROMS = list(mnames)
else: ROMS = list(mnames.difference(EXCLUDE))
ROMS.sort()

data = {}
data["source"] = "https://archive.org/download/mame0.224"
data["type"] = "zip"
data["version"] = "0.224"
data["roms"] = ROMS

# print(ROMS)
with open("../Ample/Resources/roms.plist", "w") as f:
	f.write(to_plist(data))
