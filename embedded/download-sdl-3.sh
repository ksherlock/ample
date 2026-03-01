
#!/bin/sh
VERSION=3.4.2
DMG=SDL3-${VERSION}.dmg
URL=https://www.libsdl.org/release/SDL3-${VERSION}.dmg
FRAMEWORK=SDL3.framework

if [ -e $FRAMEWORK ] ; then exit 0 ; fi

if [ ! -e $DMG ] ; then curl -OL $URL ; fi

hdiutil attach $DMG -noverify -nobrowse -mountpoint /Volumes/sdl_disk_image

ditto /Volumes/sdl_disk_image/SDL3.xcframework/macos-arm64_x86_64/$FRAMEWORK $FRAMEWORK
hdiutil detach /Volumes/sdl_disk_image

