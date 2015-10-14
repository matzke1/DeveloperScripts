# libmagic for identifying magic numbers
#
# usage: rmc_magic VERSION [BASE]
#    or: rmc_magic DIRECTORY
#    or: rmc_magic system  (or "yes")
#    or: rmc_magic no
#
export RMC_MAGIC_BASEDIR
export RMC_MAGIC_VERSION
export RMC_MAGIC_ROOT
rmc_magic() {
    rmc_parse_version_or directory magic "$@"
}

# Obtain installation directory name from version. Directory need not exist.
rmc_magic_root() {
    local base="$1" vers="$2"
    echo "$base/$vers"
}

# Obtain version number from an installation of this package
rmc_magic_version() {
    local root="$1"
    echo "unknown"
}

# Resolve package variables
rmc_magic_resolve() {
    rmc_resolve_root_and_version magic
}

# Check that this package is installed
rmc_magic_check() {
    rmc_magic_resolve
    rmc_check_root_and_version magic
    rmc_add_library_path magic lib
}
