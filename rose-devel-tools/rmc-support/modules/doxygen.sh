# doxygen executable
#
# usage: rmc_doxygen VERSION [BASE]
#    or: rmc_doxygen DIRECTORY
#    or: rmc_doxygen system (or "yes")
#    or: rmc_doxygen no
#
export RMC_DOXYGEN_BASEDIR
export RMC_DOXYGEN_VERSION=ambivalent
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

# Find executable for "system" version
rmc_doxygen_find_in_system() {
    which doxygen
}

# Resolve package variables
rmc_doxygen_resolve() {
    rmc_resolve_root_and_version doxygen
}

# Check that package is installed
rmc_doxygen_check() {
    rmc_doxygen_resolve
    rmc_check_root_and_version doxygen
}

# List installed versions
rmc_doxygen_list() {
    local base="$1"
    local dir
    for dir in $(cd "$base" && find . -follow -maxdepth 3 -name doxygen -type f -perm -100 |sort); do
	local version=$(echo "$dir" |cut -d/ -f2)
	echo "RMC_DOXYGEN_VERSION='$version'"
    done
}
