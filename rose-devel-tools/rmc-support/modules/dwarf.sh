# DWARF library
#
# usage: rmc_dwarf VERSION [BASE]
#    or: rmc_dwarf DIRECTORY
#    or: rmc_dwarf system
#    or: rmc_dwarf no
export RMC_DWARF_BASEDIR
export RMC_DWARF_VERSION
export RMC_DWARF_ROOT

rmc_dwarf() {
    rmc_parse_version_or directory dwarf "$@"
}

# Obtain installation directory name from version. Directory need not exist.
rmc_dwarf_root() {
    local base="$1" vers="$2"
    echo "$base/$vers/$RMC_CXX_VENDOR-$RMC_CXX_VERSION-$RMC_CXX_LANGUAGE"
}

# Find canonical installed file for package
rmc_dwarf_file() {
    local root="$1"
    local file="$root/include/libdwarf_version.h"
    [ -r "$file" ] && echo "$file"
}

# Find installation directory for libdwarf
rmc_dwarf_find_in_system() {
    local root="/usr";
    if [ -r "$root/include/libdwarf.h" ]; then
	echo $root;
    fi
}

# Obtain a version number from an installed package
rmc_dwarf_version() {
    local root="$1"
    local hdr="$root/include/libdwarf_version.h"
    perl -ne '/VERSION\s+?(\d+(\.\d+)+)/ && print $1' "$hdr"
}

# Resolve package variables
rmc_dwarf_resolve() {
    rmc_compiler_check
    rmc_resolve_root_and_version dwarf
    rmc_add_library_path dwarf lib
}

# Check that this package is installed
rmc_dwarf_check() {
    rmc_dwarf_resolve
    rmc_check_root_and_version dwarf
}

# List installed versions
rmc_dwarf_list() {
    local base="$1"
    local link
    for link in $(cd "$base" && find . -maxdepth 2 -type l |sort); do
	if [ -d "$base/$link/lib/." ]; then
	    local version=$(echo "$link" |cut -d/ -f2)
	    local compiler=$(echo "$link" |cut -d/ -f3)
	    local dir=$(cd "$base" && readlink "$link")
	    local date=$(echo "$dir" |sed 's/.*\([0-9][0-9][0-9][0-9]\)\([0-9][0-9]\)\([0-9][0-9]\)$/\1-\2-\3/')
	    echo "RMC_DWARF_VERSION='$version' RMC_CXX_NAME='$compiler' DATE='$date'"
	fi
    done
}
