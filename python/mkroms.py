import argparse
import re

import xml.etree.ElementTree as ET
from html.parser import HTMLParser
from os.path import splitext


from machines import MACHINES, MACHINES_EXTRA
import mame
from plist import to_plist


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
	'mac2fdhd',
	'cuda',
]


p = argparse.ArgumentParser()
p.add_argument('--full', action='store_true')
p.add_argument('--extra', action='store_true')
p.add_argument('machine', nargs="*")
args = p.parse_args()

# full = args.full
extra = args.extra
machines = args.machine
if not machines:
	if extra:
		machines = [ *MACHINES_EXTRA, *EXTRA_MACHINES]
	else:
		machines = [ *MACHINES, *EXTRA_MACHINES]

# roms stored in other files.
xEXCLUDE = [
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

# non-existent or included elsewhere.
EXCLUDE = set([
	'mac512ke',
	'maciicx',
	'maciihmu',
	'maciivi',
	'maciix',

	'macct610',
	'macct650',
	'maclc3p',
	'maclc475',
	'maclc575',
	'macqd610',
	'macqd650',

	'kb_pc83',

# ROMs for CD Drives, etc, that are intentionally hidden
# due to lack of functionality.
	'aplcd150',
    'cdd2000',
    'cdr4210',
    'cdrn820s',
    'cdu415',
    'cdu561_25',
    'cdu75s',
    'cfp1080s',
    'crd254sh',
    'cw7501',
    'smoc501',

	# amiga ntsc
	"a500n",
	"a1000n",
	"a2000n",
])

def fix_machine_description(x, devname):
	# CFFA 2.0 Compact Flash (65C02 firmware, www.dreher.net)
	x = x.replace(", www.dreher.net","")
	x = x.replace('8inch','8"') #
	x = x.replace("65C02", "65c02")
	x = re.sub(r"((^| |\()[a-z])", lambda x: x[0].upper(), x) # fix capital-case

	if devname in ("st", "megast"): x = "Atari " + x
	return x

def build_known_roms_list():
	# https://archive.org/download/mame-merged/mame-merged/
	infile = "mame-0.273-merged.html"
	# infile = "mame-0233-full.html"
	# infile = "mame-0.231-merged.html"
	rv = set()

	class X(HTMLParser):
		rv = set()

		def handle_starttag(self, tag, attrs):
			if tag != 'a': return
			href = None
			for xx in attrs:
				if xx[0] == 'href':
					href = xx[1]
					break
			if not href: return
			root, ext = splitext(href)
			if ext in (".7z", ".zip"): self.rv.add(root)


			
	x = X()
	with open(infile) as f:
		data = f.read()
		x.feed(data)
		x.close()
	return x.rv




mnames = {}
rnames = set()

known = build_known_roms_list()

known.add('macpb180c')
known.add('macpd210')
known.add('macpd270c')
known.add('macpd280c')
known.add('m68hc05pge')
known.add('a2ieee488')


for m in machines:

	print(m)

	xml = mame.run(m, "-listxml")
	root = ET.fromstring(xml)

	data = {  }


	# find machines that have a rom child
	for x in root.findall('machine/rom/..'):
		name = x.get('name')
		#if name in EXCLUDE: continue
		if name in mnames: continue

		if name not in known: continue
		# if name not in known:
		# 	print("skipping", name)
		# 	continue

		mnames[name] = x.find("description").text


		#if (name in known): mnames.add(name)
		# if name in mnames:
			# mnames[name].append(m)
		# else:
			# mnames[name] = [ m ]
		# mnames.add(name)
		# for y in x.findall('./rom'):
		# 	rnames.add(y.get('name'))
		

# print("\n\n\n")
# ll = list(mnames.difference(EXCLUDE))
# ll.sort()
# for x in ll:
# 	print(x)

# if full: ROMS = list(mnames)
# else: ROMS = list(mnames.difference(EXCLUDE))
ROMS =  [{ 'value': k, 'description': fix_machine_description(v, k)} for k, v in mnames.items()];
ROMS.sort(key=lambda x: x.get('description'))

# data = []
# data["source"] = "https://archive.org/download/mame0.224"
# data["type"] = "zip"
# data["version"] = "0.224"
#data["roms"] = ROMS

# for k in ROMS:
	# data.append( { 'value': k, 'description': mnames[k] })


# print(ROMS)
if extra:
	path = "../Ample/Resources/roms~extra.plist"
else:
	path = "../Ample/Resources/roms.plist"

with open(path, "w") as f:
	f.write(to_plist(ROMS))
