# This module is a little strange because it has no settings.

export RMC_ROSEBLD_ROOT

# Initialize package variables
rmc_rosebld_resolve() {
    local dir=$(pwd)
    while true; do
        if [ -e "$dir/$CONFIG_BASE_NAME" ]; then
	    RMC_ROSEBLD_ROOT="$dir"
            return 0;
        fi
        if [ "$dir" = "/" ]; then
	    return 0
        fi
        dir=$(realpath "$dir/..")
    done
    RMC_ROSEBLD_ROOT="$dir"
}

# Check that package is installed
rmc_rosebld_check() {
    rmc_rosebld_resolve
    if [ "$RMC_ROSEBLD_ROOT" = "" ]; then
	echo "$arg0: cannot find ROSE build directory" >&2
	exit 1
    fi
    if [ ! -d "$RMC_ROSEBLD_ROOT" ]; then
	echo "$arg0: ROSE build directory does not exist: $RMC_ROSEBLD_ROOT" >&2
	exit 1
    fi
}
