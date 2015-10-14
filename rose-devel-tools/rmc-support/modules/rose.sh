# Installed version of ROSE
export RMC_ROSE_BASEDIR
export RMC_ROSE_VERSION
export RMC_ROSE_ROOT

rmc_rose() {
    rmc_parse_version_or directory ROSE "$@"
}

# Obtain a version number from an installed package
rmc_rose_version() {
    local root="$1"
    : cannot do this yet
}

# Obtain an installation directory name from a version. Directory need not exist.
rmc_rose_root() {
    local base="$1" vers="$2"
    : cannot do this yet
}

# Resolve package variables
rmc_rose_resolve() {
    rmc_resolve_root_and_version ROSE
}

# Check that package is installed
rmc_rose_check() {
    rmc_rose_resolve
    rmc_add_library_path ROSE lib
}
