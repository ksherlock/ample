#!/bin/sh

export DYLD_FALLBACK_FRAMEWORK_PATH=../embedded

../embedded/mame64 $* -listmedia

