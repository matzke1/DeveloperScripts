# ROSE top source directory
# 
# usage: rmc_rosesrc DIRECTORY

export RMC_ROSESRC_ROOT

rmc_rosesrc() {
    RMC_ROSESRC_ROOT="$1"
}

# alternate name for rmc_rosesrc
rmc_source_dir() {
    rmc_rosesrc "$@"
}

# Initialize package variables
rmc_rosesrc_resolve() {
    if [ -d "$RMC_ROSESRC_ROOT" ]; then
	RMC_ROSESRC_ROOT=$(realpath "$RMC_ROSESRC_ROOT")
    fi
}

# Check that package is installed
rmc_rosesrc_check() {
    rmc_rosesrc_resolve
    if [ "$RMC_ROSESRC_ROOT" = "" ]; then
	echo "$arg0: ROSE source tree is required" >&2
	exit 1
    fi
    if [ ! -d "$RMC_ROSESRC_ROOT" ]; then
	echo "$arg0: ROSE source tree is missing: $RMC_ROSESRC_ROOT" >&2
	exit 1
    fi
    if [ ! -e "$RMC_ROSESRC_ROOT/src/frontend/BinaryFormats/ElfSection.C" ]; then
	echo "$arg0: does not look like a ROSE source tree: $RMC_ROSESRC_ROOT" >&2
	exit 1
    fi

    # Export a few extra variables that are used in documentation
    export RG_SRC="$RMC_ROSESRC_ROOT"
    export ROSE_SOURCE="$RMC_ROSESRC_ROOT"
}
