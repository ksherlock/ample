MACHINES = (
	"apple1",
	"apple2", "apple2p", "apple2jp",
	"apple3",

	"apple2e", "apple2ede", "apple2efr", "apple2ese", "apple2euk",
	"apple2ee", "apple2eede", "apple2eefr", "apple2ees", "apple2eese", "apple2eeuk",
	"apple2ep", "apple2epde", "apple2epfr", "apple2epse", "apple2epuk",

	"apple2gs", "apple2gsr0", "apple2gsr1", "apple2gsmt",
	"apple2c", "apple2c0", "apple2c3", "apple2c4", "apple2cp",

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
	"maciivx", "maciivi", "maciifx",
	"maclc", "maclc2", "maclc3", "maclc3p", "maclc520", "maclc550", "mactv",

	# mac 128k-classic
	"mac128k", "mac512k", "mac512ke", "macplus", "macse", "macsefd", "macse30",
	"macclasc", "macclas2", "maccclas",

	# quadra
	"macqd700", "macqd800", "macct610", "macct650", "macqd610", "macqd650",
	"macqd605", "maclc475", "maclc575", "macqd630", "maclc580", "macqd900", "macqd950",

	# portable
	"macprtb", "macpb100",
	# powerbook
	"macpb140", "macpb145", "macpb145b", "macpb160", "macpb165", "macpb165c", "macpb170", "macpb180", "macpb180c",

	# 128k clones
	# "unitron", "utrn1024",

	#atari
	"st", "megast",

	# trs
	"coco", "coco2b", "coco3", "coco3p", "mc10",
	"cocoh", "coco3h", "coco2bh",
	"trs80", "trs80l2",
	"dragon32", "dragon64", "d64plus", "dragon200", "dragon200e", "tanodr64",

	# oric
	"oric1", "orica", "prav8d", "telstrat",
	# mt65, micron, mt6809 -- need tanbus support...



	# acorn
	"bbcb", "bbca", "bbcb_de", "bbcb_us", "bbcb_no", "bbcbp", "bbcbp128", "bbcm", "bbcmt", "bbcmc", "electron",

)


MACHINES_EXTRA = MACHINES + (

	# other (for Ample-lite...)

	# commodore
	"c64", "c64c", "c128",


	# amiga
	"a500", "a500n", "a1000", "a1000n", "a2000", "a2000n",


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
	"fdc", # bbc fdc
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

	# amiga
	"zorro1", "zorro2", "zorro3", "zorro4", "zorro5",

	# dec
	"eia", "host", "com_port", "prt_port",
	"rs232a", "rs232b", "serial0", "serial1", "tty0", "tty1",
	"kbd", "mse", "keyboard", "kbd_con", "mouseport",

	"isa0", "isa1", "isa2", "isa3", "isa4", "isa5", "isa6", "isa7", "isa8", "isa9",
	"qbus:1", "qbus:2", "qbus:3", "qbus:4", "qbus:5",

	# bbc
	"rs423", "tube", "econet254", "analogue", "userport", "internal", "1mhzbus",

	# coco/trs
	"ext", "floppy0", "floppy1", "floppy2", "floppy3",

	# commodore
	"user", "iec4", "iec8", "iec9", "iec10", "iec11", "tape"
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
	"rs232":      "Serial",
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

	"zorro1":     "Zorro 1",
	"zorro2":     "Zorro 2",
	"zorro3":     "Zorro 3",
	"zorro4":     "Zorro 4",
	"zorro5":     "Zorro 5",


	"kbd":        "Keyboard",
	"keyboard":   "Keyboard",
	"kbd_con":    "Keyboard",
	"mse":        "Mouse",
	"mouseport":  "Mouse",

	"rs423":      "Serial",
	"eia":        "Serial",
	"host":       "Serial",
	"com_port":   "Serial",
	"prt_port":   "Printer",
	"rs232a":     "Serial A",
	"rs232b":     "Serial B",
	"serial0":    "Serial 0",
	"serial1":    "Serial 1",
	"tty0":       "TTY 0",
	"tty1":       "TTY 1",

	"isa0":       "Slot 0",
	"isa1":       "Slot 1",
	"isa2":       "Slot 2",
	"isa3":       "Slot 3",
	"isa4":       "Slot 4",
	"isa5":       "Slot 5",
	"isa6":       "Slot 6",
	"isa7":       "Slot 7",
	"isa8":       "Slot 8",
	"isa9":       "Slot 9",

	"qbus:1":     "Q-Bus 1",
	"qbus:2":     "Q-Bus 2",
	"qbus:3":     "Q-Bus 3",
	"qbus:4":     "Q-Bus 4",
	"qbus:5":     "Q-Bus 5",

	"tube":       "Tube",
	"econet254":  "Econet",
	"analogue":   "Analog Port",
	"userport":   "User Port",
	"internal":   "Internal",
	"1mhzbus":    "1MHz Bus",
	"fdc":        "Disk Drives",


	# "ext":        "Coco Cart",
	"ext":        "Expansion",
	"floppy0":    "Floppy 1",
	"floppy1":    "Floppy 2",
	"floppy2":    "Floppy 3",
	"floppy3":    "Floppy 4",

	# commodore
	"user":       "User",
	"tape":       "Tape",
	"iec4":       "IEC 4",
	"iec5":       "IEC 5",
	"iec6":       "IEC 6",
	"iec7":       "IEC 7",
	"iec8":       "IEC 8",
	"iec9":       "IEC 9",
	"iec10":      "IEC 10",
	"iec11":      "IEC 11",
	"iec12":      "IEC 12",
}


