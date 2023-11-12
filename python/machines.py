MACHINES = (
	"apple1",
	"apple2", "apple2p", "apple2jp",
	"apple3",
	"apple2e", "apple2ees", "apple2euk", "apple2ep",
	"apple2ee", "apple2eeuk", "apple2eefr",
	"apple2gs", "apple2gsr0", "apple2gsr1",
	"apple2c", "apple2cp",

	# laser family
	"laser128", "laser2c", "las128ex", "las128e2", "laser128o",

	# Franklin
	"ace100", "ace500", "ace1000", "ace2200",

	# IIe clones
	"mprof3", "prav8c", "spectred", "tk3000",
	# II clones
	"agat7", "agat9", "albert",
	"am100", "am64", "basis108", "craft2p",
	"dodo", "elppa", "hkc8800a", "ivelultr",
	"maxxi", "microeng", "prav82", "prav8m",
	"space84", "uniap2en", "uniap2pt", "uniap2ti",
	"zijini",
	# China Education Computer
	"cec2000", "cece", "cecg", "ceci", "cecm",
	"las3000",


	# macintosh...
	"macii", "maciihmu", "mac2fdhd", "maciix", "maciicx", "maciici", "maciisi",
	"maciivx", "maciivi",
	"maclc", "maclc2", "maclc3", "maclc3p", "maclc520", "maclc550",

	# mac 128k-classic
	"mac128k", "mac512k", "mac512ke", "macplus", "macse", "macsefd", "macse30",
	"macclasc", "macclas2", "maccclas",

	# quadra
	"macqd700", "macqd800", "macct610", "macct650", "macqd610", "macqd650",
	"macqd605", "maclc475", "maclc575", "macqd630", "maclc580",
	# 128k clones
	# "unitron", "utrn1024",

	#atari
	"st", "megast",
)


MACHINES_EXTRA = MACHINES + (

	# other (for Ample-lite...)
	# DEC
	"vt52", "vt100", "vt101", "vt102", "vt240",
	"ds2100", "ds3100", "ds5k133", "pdp11qb", "pdp11ub", "pdp11ub2",
	# IBM
	"rtpc010", "rtpc015", "rtpc020", "rtpc025", "rtpca25",
	# HP
	"hp9k310", "hp9k320", "hp9k330", "hp9k332", "hp9k340", "hp9k360", "hp9k370", "hp9k380", "hp9k382",
	# Intergraph
	"ip2000", "ip2400", "ip2500", "ip2700", "ip2800", "ip6000", "ip6400", "ip6700", "ip6800",
	# MIPS
	"rc2030", "rs2030", "rc3230", "rs3230",
	# SGI
	"indigo", "indigo2_4415", "indigo_r4000", "indigo_r4400", "indy_4610", "indy_4613", "indy_5015", "pi4d20", "pi4d25", "pi4d30", "pi4d35",
	# Sony
	"nws3260", "nws3410", "nws1580", "nws5000x",
	# SUN
	"sun1", "sun2_50", "sun2_120", "sun3_50", "sun3_60", "sun3_110", "sun3_150", "sun3_260", "sun3_e", "sun3_80", "sun4_40", "sun4_50", "sun4_20", "sun4_25", "sun4_65",
# "sun3_460", "sun4_400", "sun4_110", "sun4_300",  "sun4_60", "sun4_75", "sun_s10", "sun_s20"

	)


SLOTS = (
	"sl0", "sl1", "sl2", "sl3",
	"sl4", "sl5", "sl6", "sl7",
	"exp", "aux",
	"rs232",
	"gameio",
	"printer",
	"modem",

	# mac nubus
	"nb1", "nb2", "nb3", "nb4", "nb5", "nb6", "nb7",
	"nb8", "nb9", "nba", "nbb", "nbc", "nbd", "nbe",

	"pds", "pds030", "lcpds",

	# st
	"centronics", "mdin", "mdout",

	# dec
	"eia", "host", "com_prt", "prt_port"
)

SLOT_NAMES = {
	"ramsize":    "RAM",
	"bios":       "ROM",
	"sl0":        "Slot 0",
	"sl1":        "Slot 1",
	"sl2":        "Slot 2",
	"sl3":        "Slot 3",
	"sl4":        "Slot 4",
	"sl5":        "Slot 5",
	"sl6":        "Slot 6",
	"sl7":        "Slot 7",
	"exp":        "Expansion",
	"aux":        "Auxiliary",
	"rs232":      "Modem",
	"gameio":     "Game I/O",
	"modem":      "Modem",
	"printer":    "Printer",

	"nb9":        "Slot 9",
	"nba":        "Slot A",
	"nbb":        "Slot B",
	"nbc":        "Slot C",
	"nbd":        "Slot D",
	"nbe":        "Slot E",

	"pds":        "PDS",
	"pds030":     "PDS",
	"lcpds":      "PDS",

	"centronics": "Printer",
	"mdin":       "MIDI In",
	"mdout":      "MIDI Out",

	"eia":        "Modem",
	"host":       "Modem",
	"com_prt":    "Modem",
	"prt_port":   "Printer"
}
