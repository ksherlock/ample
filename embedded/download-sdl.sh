
#!/bin/sh
VERSION=2.26.3
DMG=SDL2-${VERSION}.dmg
URL=https://www.libsdl.org/release/SDL2-${VERSION}.dmg
FRAMEWORK=SDL2.framework

if [ -e $FRAMEWORK ] ; then exit 0 ; fi

if [ ! -e $DMG ] ; then curl -OL $URL ; fi

hdiutil attach $DMG -noverify -nobrowse -mountpoint /Volumes/sdl_disk_image

# cp -r /sdl_disk_image/$FRAMEWORK ./
ditto /Volumes/sdl_disk_image/$FRAMEWORK $FRAMEWORK
hdiutil detach /Volumes/sdl_disk_image
