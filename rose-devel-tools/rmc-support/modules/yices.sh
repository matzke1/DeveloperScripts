# Yices SMT solver
#
# usage: rmc_yices VERSION [BASE]
#    or: rmc_yices DIRECTORY
#    or: rmc_yices system (or "yes")
#    or: rmc_yices no
#
export RMC_YICES_BASEDIR
export RMC_YICES_VERSION
export RMC_YICES_ROOT
rmc_yices() {
    rmc_parse_version_or directory yices "$@"
}

# Obtain a version number from an installed package
rmc_yices_version() {
    local root="$1"
    : cannot do this yet
}

# Obtain an installation directory name from a version. Directory need not exist.
rmc_yices_root() {
    local base="$1" vers="$2"
    echo "$base/$vers"
}

# Resolve package variables.
rmc_yices_resolve() {
    rmc_resolve_root_and_version yices
}

# Check that package is installed
rmc_yices_check() {
    rmc_yices_resolve
    rmc_check_root_and_version yices
}
