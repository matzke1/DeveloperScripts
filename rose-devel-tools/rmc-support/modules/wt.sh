# Wt web toolkit
#
# usage: rmc_web_toolkit VERSION [BASE]
#    or: rmc_web_toolkit DIRECTORY
#    or: rmc_web_toolkit no
#
export RMC_WT_BASEDIR
export RMC_WT_VERSION
export RMC_WT_ROOT
rmc_wt() {
    rmc_parse_version_or directory Wt "$@"
}

# Obtain installation directory name from version. Directory need not exist.
rmc_wt_root() {
    local base="$1" vers="$2"
    echo "$base/$vers/boost-$RMC_BOOST_VERSION/$RMC_CXX_VENDOR-$RMC_CXX_VERSION-$RMC_CXX_LANGUAGE"
}


# Obtain a version number from an installation of Wt
rmc_wt_version() {
    local root="$1"
    local hdr="$root/include/Wt/WConfig.h"
    perl -ne '/WT_VERSION_STR\s+"(\d+(\.\d+)+)"/ && print $1' "$hdr"
}

# Resolve package variables
rmc_wt_resolve() {
    rmc_compiler_check
    rmc_boost_check

    if [ "$RMC_WT_VERSION" = "system" ]; then
        echo "$arg0: do not use system-insalled Wt" >&2
        exit 1
    fi
    rmc_resolve_root_and_version Wt
    rmc_add_library_path Wt lib
}

# Check that package is installed
rmc_wt_check() {
    rmc_wt_resolve
    rmc_check_root_and_version Wt
}
