from plist import to_plist

ROMS = """
a1cass
a2aevm80
a2ap16
a2ap16a
a2aplcrd
a2cffa02
a2cffa2
a2corvus
a2diskii
a2diskiing
a2focdrv
a2hsscsi
a2iwm
a2memexp
a2mouse
a2pic
a2ramfac
a2scsi
a2ssc
a2surance
a2swyft
a2thunpl
a2tmstho
a2twarp
a2ultrme
a2ulttrm
a2vidtrm
a2vtc1
a2vulcan
a2vulgld
a2vuliie
a2zipdrv
a3fdc
apple1
apple2
apple2c
apple2e
apple2gs
apple3
cec2000
cece
cecg
ceci
cecm
cga
cmsscsi
d2fdc
diskii13
keytronic_pc3270
m68705p3
votrax
zijini
""".splitlines()
#
# others
# mprof3
# spectred
# tk3000
# prav8c
#

ROMS.remove("")
ROMS.sort()

data = {}
data["source"] = "https://archive.org/download/mame0224_rom"
data["type"] = "7z"
data["version"] = "0.224"
data["roms"] = ROMS

# print(ROMS)
with open("../Ample/Resources/roms.plist", "w") as f:
	f.write(to_plist(data))
