
import xml.etree.ElementTree as ET
import re
import sys
import argparse

from plist import to_plist
from machines import MACHINES, MACHINES_EXTRA
import mame


apple1_children = None
apple2_children = ["apple2", "apple2p", "apple2jp"]
apple3_children = None
apple2e_children = ["apple2e", "apple2ees", "apple2euk", "apple2ep", "apple2ee", "apple2eeuk", "apple2eefr"]
apple2c_children = ["apple2c", "apple2c0", "apple2c3", "apple2c4", "apple2cp"]
apple2gs_children = ["apple2gsr0", "apple2gsr1", "apple2gs"]
laser_children = ["las3000", "laser2c", "laser128", "laser128o", "las128ex", "las128e2"]
franklin_children = ["ace100", "ace500", "ace1000", "ace2200"]
ii_clones_children = ["albert",
	"am100", "am64", "basis108", "craft2p",
	"dodo", "elppa", "hkc8800a", "ivelultr",
	"maxxi", "microeng", "prav82", "prav8m",
	"space84", "uniap2en", "uniap2pt", "uniap2ti"]
iie_clones_children = ["mprof3", "prav8c", "spectred", "tk3000", "zijini"]
cec_children = ["cec2000", "cece", "cecg", "ceci", "cecm"]
agat_children = ["agat7", "agat9"]

mac_ii_children = [
	"macii", "maciihmu", "mac2fdhd", "maciix", "maciifx", "maciicx", "maciici", "maciisi", "maciivx", "maciivi", 

]

mac_lc_children = [
	"maclc", "maclc2", "maclc3", "maclc3p",
	"maclc475", "maclc520", "maclc550", "maclc575",
	"macct610", "macct650", "mactv",
]
# maclc50" / macqd630 slots are messed up right now.

mac_quadra_children = [
	"macqd605", "macqd610", "macqd650", "macqd700", "macqd800", "macqd900", "macqd950"
]

# se/30 and classic 2 are implemented as a nubus but i'm sticking then with the 128 due to the form factor.
mac_128k_children = ["mac128k", "mac512k", "mac512ke", "macplus",
	"macse", "macsefd", "macse30", "macclasc", "macclas2", "maccclas"]


mac_portable_children = ["macprtb", "macpb100"]

atari_st_children = ["st", "megast"]

tandy_children = [
	"trs80", "trs80l2",
	"coco", "cocoh",
	"coco2b", "coco2bh",
	"coco3", "coco3p", "coco3h",
	"mc10",
	"dragon32", "dragon64", "d64plus", "dragon200", "dragon200e", "tanodr64",
]

oric_children = [
	"oric1", "orica", "prav8d", "telstrat",
]


amiga_children = ["a500", "a500n", "a1000", "a1000n", "a2000", "a2000n" ]

acorn_children = [ "bbcb", "bbca", "bbcb_de", "bbcb_us", "bbcb_no", "bbcbp", "bbcbp128", "bbcm", "bbcmt", "bbcmc", "electron" ]

dec_vt_children = ["vt52", "vt100", "vt101", "vt102", "vt240"]
dec_children = ["ds2100", "ds3100", "ds5k133", "pdp11qb", "pdp11ub", "pdp11ub2"]
ibm_rt_children = ["rtpc010", "rtpc015", "rtpc020", "rtpc025", "rtpca25"]
hp_9000_children = ["hp9k310", "hp9k320", "hp9k330", "hp9k332", "hp9k340", "hp9k360", "hp9k370", "hp9k380", "hp9k382"]
intergraph_children = ["ip2000", "ip2400", "ip2500", "ip2700", "ip2800", "ip6000", "ip6400", "ip6700", "ip6800"]
mips_children = ["rc2030", "rs2030", "rc3230", "rs3230"]
sgi_children = ["indigo", "indigo2_4415", "indigo_r4000", "indigo_r4400", "indy_4610", "indy_4613", "indy_5015", "pi4d20", "pi4d25", "pi4d30", "pi4d35"]
sony_children = ["nws3260", "nws3410", "nws1580", "nws5000x"]
sun_children = [
	"sun1", "sun2_50", "sun2_120", "sun3_50", "sun3_60", "sun3_110", "sun3_150", "sun3_260", "sun3_e", "sun3_80",
	"sun4_40", "sun4_50", "sun4_20", "sun4_25", "sun4_65",
]

TREE = [
	("Apple I", "apple1", apple1_children),
	("Apple ][", "apple2", apple2_children),
	("Apple IIe", "apple2e", apple2e_children),
	("Apple //c", "apple2c", apple2c_children),
	("Apple IIgs", "apple2gs", apple2gs_children),
	("Apple ///", "apple3", apple3_children),
	("II Clones", None, ii_clones_children),
	("IIe Clones", None, iie_clones_children),
	("Franklin", None, franklin_children),
	("Laser", "laser128", laser_children),
	("Agat", "agat7", agat_children),
	("China Education Computer", None, cec_children),
	("Macintosh (Compact)", "macse30", mac_128k_children),
	("Macintosh (II)", "maciix", mac_ii_children),
	("Macintosh (Quadra)", None, mac_quadra_children),
	("Macintosh (LC)", None, mac_lc_children),
	("Macintosh (Portable)", None, mac_portable_children),
	("Atari ST", "st", atari_st_children),
	("Oric", None, oric_children),
	("Tandy", None, tandy_children),
]

TREE_EXTRA = TREE + [
	("Acorn", None, acorn_children),
	("Amiga", None, amiga_children),
	("DEC VT", None, dec_vt_children),
	("DEC", None, dec_children),
	("HP 9000", None, hp_9000_children),
	("IBM RT", None, ibm_rt_children),
	("Intergraph", None, intergraph_children),
	("MIPS", None, mips_children),
	("SGI", None, sgi_children),
	("Sony", None, sony_children),
	("SUN", None, sun_children),
]



extra = False
machines = MACHINES
tree = TREE


p = argparse.ArgumentParser()
p.add_argument('--extra', action='store_true')
p.add_argument('machine', nargs="*")
args = p.parse_args()

extra = args.extra

if extra:
	machines = MACHINES_EXTRA
	tree = TREE_EXTRA


# Name:             Description:
# apple2gs          "Apple IIgs (ROM03)"
# apple2gsr0        "Apple IIgs (ROM00)"

names = {}

#t = st.stdout

t = mame.run("-listfull", *machines)

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

if extra:
	path = "../Ample/Resources/models~extra.plist"
else:
	path = "../Ample/Resources/models.plist"
with open(path, "w") as f:
	f.write(to_plist(data))

