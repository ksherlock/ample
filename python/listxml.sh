#!/bin/sh

export DYLD_FALLBACK_FRAMEWORK_PATH=../embedded

for machine in $* ; do ../embedded/mame64 "$machine" -listxml -nodtd ; done

