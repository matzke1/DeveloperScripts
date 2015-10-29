# doxygen executable
#
# usage: rmc_doxygen VERSION [BASE]
#    or: rmc_doxygen DIRECTORY
#    or: rmc_doxygen system (or "yes")
#    or: rmc_doxygen no
#
export RMC_DOXYGEN_BASEDIR
export RMC_DOXYGEN_VERSION
export RMC_DOXYGEN_ROOT
export RMC_DOXYGEN_FILE

rmc_doxygen() {
    rmc_parse_version_or file doxygen "$@"
}

# Obtain a version number from an installed package
rmc_doxygen_version() {
    local doxygen="$1"
    local output=$("$doxygen" --version 2>&1 |head -n1)
    perl -e '$ARGV[0] =~ /(\d+(\.\d+)+)/ && print $1' "$output"
}

# Obtain an installation directory name from a version. Directory need not exist.
rmc_doxygen_root() {
    local base="$1" vers="$2"
    echo "$base/$vers"
}

# Find canonical installed file for package
rmc_doxygen_file() {
    local root="$1"
    local file="$root/bin/doxygen"
    [ -r "$file" ] && echo "$file"
}

# Resolve package variables
rmc_doxygen_resolve() {
    rmc_resolve_root_and_version doxygen
}

# Check that package is installed
rmc_doxygen_check() {
    rmc_doxygen_resolve
    rmc_resolve_root_and_version doxygen
}
