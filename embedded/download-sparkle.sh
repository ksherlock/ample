
#!/bin/sh

VERSION=2.2.0
TAR=Sparkle-${VERSION}.tar.xz
URL=https://github.com/sparkle-project/Sparkle/releases/download/${VERSION}/Sparkle-${VERSION}.tar.xz
FRAMEWORK=Sparkle.framework

if [ -e $FRAMEWORK ] ; then exit 0 ; fi

if [ ! -e $TAR ] ; then curl -OL $URL ; fi

mkdir -p Sparkle-${VERSION}
cd Sparkle-${VERSION}
if [ ! -e $FRAMEWORK ] ; then tar xfz ../$TAR ; fi
cd ..

ditto Sparkle-${VERSION}/$FRAMEWORK $FRAMEWORK

# older version of xcode need a Versions/A directory

SW_VERSION=`sw_vers -productVersion`
case $SW_VERSION in
  10.14|10.14.*) 
    if [ ! -e $FRAMEWORK/Versions/A ] ; then ln -s B $FRAMEWORK/Versions/A ; fi
esac 

