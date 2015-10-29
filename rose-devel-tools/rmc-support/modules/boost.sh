# Boost installation directory
#
# usage: rmc_boost VERSION [BASE]
#    or: rmc_boost DIRECTORY
#
export RMC_BOOST_BASEDIR
export RMC_BOOST_VERSION
export RMC_BOOST_ROOT
export RMC_BOOST_FILE

rmc_boost() {
    rmc_parse_version_or directory boost "$@"
}

# Return version number for existing boost
rmc_boost_version() {
    local root="$1"
    local hdr="$root/include/boost/version.hpp"
    perl -ne '/BOOST_LIB_VERSION\s+"([_0-9]+)"/ && print $1' "$hdr" |tr _ .
}

# Boost installation root from version number
rmc_boost_root() {
    local base="$1" vers="$2"
    echo "$base/$vers/$RMC_CXX_VENDOR-$RMC_CXX_VERSION"
}

# Find canonical installed file for package
rmc_boost_file() {
    local root="$1"
    local file="$root/include/boost/version.hpp"
    [ -r "$file" ] && echo "$file"
}

# Resolve boost variables
rmc_boost_resolve() {
    rmc_compiler_check
    if [ "$RMC_BOOST_VERSION" = "system" ]; then
        echo "$arg0: do not use system-installed boost" >&2
        exit 1
    fi
    if [ "$RMC_BOOST_VERSION" = "no" ]; then
	echo "$arg0: boost is required" >&2
	exit 1
    fi
    rmc_resolve_root_and_version boost
    rmc_add_library_path boost lib
}

# Check boost consistency and existence
rmc_boost_check() {
    rmc_boost_resolve
    rmc_check_root_and_version boost
}
