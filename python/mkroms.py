import argparse
import re

import xml.etree.ElementTree as ET
from html.parser import HTMLParser
from os.path import splitext


from machines import MACHINES, MACHINES_EXTRA
import mame
from plist import to_plist

#
# merged algo -- rom are included, device_ref's are NOT.
# 1 file per parent.




# standalone vgmplay????
EXTRA_MACHINES = [
	"vgmplay",
	"a2pcxport"
]

EXCLUDE = set()

# EXCLUDE = set([
# 	"a2lancegs",
# ])

def machine_has_roms(m):
	rv = False
	for x in m.findall('./rom'):
		if x.get("status") == "nodump": continue
		rv = True
	return rv
	# if rv: return rv
	# if m.find('./biosset') != None: return true
	# return False

def machine_description(m):
	desc = m.find("description").text
	return desc

def fix_machine_description(x, devname):
	# CFFA 2.0 Compact Flash (65C02 firmware, www.dreher.net)
	x = x.replace(", www.dreher.net","")
	x = x.replace('8inch','8"') #
	x = x.replace("65C02", "65c02")
	x = re.sub(r"((^| |\()[a-z])", lambda x: x[0].upper(), x) # fix capital-case

	if devname in ("st", "megast"): x = "Atari " + x
	return x


p = argparse.ArgumentParser()
p.add_argument('--full', action='store_true')
p.add_argument('--extra', action='store_true')
p.add_argument('machine', nargs="*")
args = p.parse_args()

extra = args.extra
machines = args.machine
if not machines:
	if extra:
		machines = [ *MACHINES_EXTRA, *EXTRA_MACHINES]
	else:
		machines = [ *MACHINES, *EXTRA_MACHINES]

romdata = {  }
parents = set()
processed = set()

for mname in machines:

	print(mname)

	xml = mame.run(mname, "-listxml")
	root = ET.fromstring(xml)

	# todo -- if child in included and has roms, mark them with the parent.

	first = True
	# included = set()
	for m in root.findall('./machine'):

		nm = m.get('name')
		if nm in EXCLUDE: continue
		if nm in processed: continue

		processed.add(nm)
		parent = m.get('romof')

		if parent: parents.add(parent)

		needs_roms = parent == None and machine_has_roms(m)

		if needs_roms:
			romdata[nm] = machine_description(m)
			#included.add(nm)

		# if first:
		# 	first = False

		# 	for x in m.findall('./device_ref'):
		# 		nm = x.get('name')
		# 		included.add(nm)

		# 	# print(included)
		# 	continue


ROMS =  [{ 'value': k, 'description': fix_machine_description(v, k)} for k, v in romdata.items()];
ROMS.sort(key=lambda x: x.get('description'))
# print(ROMS)

missing = parents - processed
if len(missing):
	print('Missing parents:')
	for x in missing: print(x)


if extra:
	path = "../Ample/Resources/roms~extra.plist"
else:
	path = "../Ample/Resources/roms.plist"

with open(path, "w") as f:
	f.write(to_plist(ROMS))
