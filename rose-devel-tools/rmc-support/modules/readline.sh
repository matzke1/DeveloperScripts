# Readline input library
#
# usage: rmc_readline VERSION [BASE]
#    or: rmc_readline DIRECTORY
#    or: rmc_readline system (or "yes")
#    or: rmc_readline no
#
export RMC_READLINE_BASEDIR
export RMC_READLINE_VERSION
export RMC_READLINE_ROOT
rmc_readline() {
    rmc_parse_version_or directory readline "$@"
}

# Obtain a version number from an installed package
rmc_readline_version() {
    local root="$1"
    local hdr="$root/include/readline/readline.h"
    local major=$(perl -ne '/RL_VERSION_MAJOR\s+(\d+)/ && print $1' "$hdr")
    local minor=$(perl -ne '/RL_VERSION_MINOR\s+(\d+)/ && print $1' "$hdr")
    echo "$major.$minor"
}

# Obtain an installation directory name from a version. Directory need not exist.
rmc_readline_root() {
    local base="$1" vers="$2"
    echo "$base/$vers"
}

# Find canonical installed file for package
rmc_readline_file() {
    local root="$1"
    local file="$root/include/readline/readline.h"
    [ -r "$file" ] && echo "$file"
}

# Find installation root in filesystem
rmc_readline_find_in_system() {
    : not implemented
}

# Resolve package variables
rmc_readline_resolve() {
    rmc_resolve_root_and_version readline
    rmc_add_library_path readline lib
}

# Check that package is installed
rmc_readline_check() {
    rmc_readline_resolve
    rmc_check_root_and_version readline
}
