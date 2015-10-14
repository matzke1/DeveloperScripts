# python executable
#
# usage: rmc_python VERSION [BASE]
#    or: rmc_python DIRECTORY
#    or: rmc_python system (or "yes")
#    or: rmc_python no
#
export RMC_PYTHON_BASEDIR
export RMC_PYTHON_VERSION
export RMC_PYTHON_ROOT
rmc_python() {
    rmc_parse_version_or file python "$@"
}

# Obtain a version number from an installed package
rmc_python_version() {
    local python="$1"
    local output=$("$python" --version 2>&1 |head -n1)
    perl -e '$ARGV[0] =~ /(\d+(\.\d+)+)/ && print $1' "$output"
}

# Obtain an installation directory name from a version. Directory need not exist.
rmc_python_root() {
    local base="$1" vers="$2"
    echo "$base/$vers"
}

# Resolve package variables
rmc_python_resolve() {
    rmc_resolve_root_and_version python
}

# Check that package is installed
rmc_python_check() {
    rmc_python_resolve
    rmc_check_root_and_version python
}
