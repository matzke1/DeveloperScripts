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
    echo "$base/$vers/$RMC_OS_NAME_FILE"
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
    rmc_os_check
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
    local link
    for link in $(cd "$base" && find . -maxdepth 2 -type l |sort); do
	if [ -e "$base/$link/bin/doxygen" ]; then
	    local version=$(echo "$link" |cut -d/ -f2)
	    local os=$(echo "$link" |cut -d/ -f3)
	    local dir=$(cd "$base" && readlink "$link")
	    local date=$(echo "$dir" |sed 's/.*\([0-9][0-9][0-9][0-9]\)\([0-9][0-9]\)\([0-9][0-9]\)$/\1-\2-\3/')
	    echo "RMC_DOXYGEN_VERSION='$version' RMC_OS_NAME='$os' DATE='$date'"
	fi
    done
}
