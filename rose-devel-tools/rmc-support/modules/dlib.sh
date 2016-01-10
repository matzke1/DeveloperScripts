# dlib
#
# usage: rmc_dlib VERSION [BASE]
#    or: rmc_dlib DIRECTORY
#    or: rmc_dlib system (or "yes")
#    or: rmc_dlib no
#
export RMC_DLIB_BASEDIR
export RMC_DLIB_VERSION="none"
export RMC_DLIB_ROOT
rmc_dlib() {
    rmc_parse_version_or directory dlib "$@"
}

# Obtain a version number from an installed package
rmc_dlib_version() {
    local root="$1"
    local hdr="$root/dlib/revision.h"
    local major=$(perl -ne '/DLIB_MAJOR_VERSION\s+(\d+)/ && print $1' "$hdr")
    local minor=$(perl -ne '/DLIB_MINOR_VERSION\s+(\d+)/ && print $1' "$hdr")
    echo "$major.$minor"
}

# Obtain installation directory name from version. Directory need not exist
rmc_dlib_root() {
    local base="$1" vers="$2"
    echo "$base/$vers"
}

# Find canonical installed file for package
rmc_dlib_file() {
    local root="$1"
    local file="$root/dlib/revision.h"
    [ -r "$file" ] && echo "$file"
}

# Find library root in filesystem
rmc_dlib_find_in_system() {
    : not implemented
}

# Resolve package variables
rmc_dlib_resolve() {
    rmc_resolve_root_and_version dlib
}

# Check that package is installed
rmc_dlib_check() {
    rmc_dlib_resolve
    rmc_check_root_and_version dlib
}
