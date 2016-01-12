# SQLite database library
#
# usage: rmc_sqlite VERSION [BASE]
#    or: rmc_sqlite DIRECTORY
#    or: rmc_sqlite system (or "yes")
#    or: rmc_sqlite no
#
export RMC_SQLITE_BASEDIR
export RMC_SQLITE_VERSION
export RMC_SQLITE_ROOT
rmc_sqlite() {
    rmc_parse_version_or directory sqlite "$@"
}

# Obtain a version number from an installed package
rmc_sqlite_version() {
    local root="$1"
    : cannot do this yet
}

# Obtain an installation directory name from a version. Directory need not exist.
rmc_sqlite_root() {
    local base="$1" vers="$2"
    : cannot do this yet
}

# Find installation root in filesystem
rmc_sqlite_find_in_system() {
    [ -r "/usr/include/sqlite3.h" ] && echo "/usr"
}

# Resolve package variables
rmc_sqlite_resolve() {
    rmc_resolve_root_and_version sqlite
    rmc_add_library_path sqlite lib
}

# Check that package is installed
rmc_sqlite_check() {
    rmc_sqlite_resolve
    rmc_check_root_and_version sqlite
}
