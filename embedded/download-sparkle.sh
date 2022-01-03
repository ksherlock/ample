
#!/bin/sh

VERSION=2.0.0
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
