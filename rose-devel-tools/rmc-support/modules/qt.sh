# Qt widget library
#
# usage: rmc_qt VERSION [BASE]
#    or: rmc_qt DIRECTORY
#    or: rmc_qt system (or "yes")
#    or: rmc_qt no
#
export RMC_QT_BASEDIR
export RMC_QT_VERSION
export RMC_QT_ROOT
rmc_qt() {
    rmc_parse_version_or directory Qt "$@"
}

# Obtain a version number from an installed package
rmc_qt_version() {
    local root="$1"
    : cannot do this yet
}

# Obtain an installation directory name from a version. Directory need not exist.
rmc_qt_root() {
    local base="$1" vers="$2"
    : cannot do this yet
}

# Resolve package variables
rmc_qt_resolve() {
    rmc_compiler_check
    rmc_resolve_root_and_version Qt
    rmc_add_library_path Qt lib
}

# Check that package is installed
rmc_qt_check() {
    rmc_qt_resolve
}
