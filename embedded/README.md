
This folder should contain SDL2.framework and a mame64 executable.  These will be included in the build.

* [SDL2](http://libsdl.org/download-2.0.php)
* [MAME](https://github.com/mamedev/mame) (requires building from source)

Not tested, but perhaps you could also download a [pre-built MAME](https://wiki.mamedev.org/index.php/SDL_Supported_Platforms) and use `install_name_tool` to fix the rpath.

Alternatively, adjust the xcode project to not embed them.


Building MAME:

	This will build a subset of MAME which only includes apple2 support.

    git clone mame ...
    cd mame
    make SOURCES=src/mame/drivers/apple1.cpp,src/mame/drivers/apple2.cpp,src/mame/drivers/apple2e.cpp,src/mame/drivers/apple2gs.cpp,src/mame/drivers/apple3.cpp SDL_FRAMEWORK_PATH=`pwd`/..

    you can use `$LDFLAGS` to set the rpath (`LDFLAGS="-rpath @executable_path/../Frameworks" make ...`) or set it after with the `install_name_tool` tool - ``install_name_tool -add_rpath @executable_path/../Frameworks mame64`


