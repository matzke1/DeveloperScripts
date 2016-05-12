#!/bin/bash

# Intel compilers require sourcing a script to set up environment variables, but
# we find that very inconvenient.  So instead, we provide a wrapper around the
# script and compiler.  The wrapper has many symlinks named icpc-VERSION,
# icc-VERSION, and ifort-VERSION.

COMPILER_CMD_VERSION="${0##*/}"
COMPILER_CMD=$(echo "$COMPILER_CMD_VERSION" |cut -d- -f1)
COMPILER_VERSION=$(echo "$COMPILER_CMD_VERSION" |cut -d- -f2)
COMPILER_VENDOR=intel

if [ "$RMC_OS_NAME_FILE" = "" ]; then
   eval $(rmc resolve os)
fi

COMPILER_ROOT="$RMC_RMC_TOOLCHAIN/compiler/$COMPILER_VENDOR-$COMPILER_VERSION/$RMC_OS_NAME_FILE"
if [ ! -d "$COMPILER_ROOT/." ]; then
   echo "$0: cannot find compiler root: $COMPILER_ROOT" >&2
   exit 1
fi

source "$COMPILER_ROOT/bin/iccvars.sh" intel64
exec "$COMPILER_CMD" "$@"
