# YAML parsing library
#
# usage: rmc_yaml VERSION [BASE]
#    or: rmc_yaml DIRECTORY
#    or: rmc_yaml system (or "yes")
#    or: rmc_yaml no
#
export RMC_YAML_BASEDIR
export RMC_YAML_VERSION
export RMC_YAML_ROOT
rmc_yaml() {
    rmc_parse_version_or directory yaml "$@"
}

# Obtain a version number from an installed package
rmc_yaml_version() {
    local root="$1"
    perl -e '$ARGV[0] =~ /\byaml.*?(\d+(\.\d+)+)/ && print $1' "$root"
}

# Obtain an installation directory name from a version. Directory need not exist.
rmc_yaml_root() {
    local base="$1" vers="$2"
    echo "$base/$vers/boost-$RMC_BOOST_VERSION/$RMC_CXX_VENDOR-$RMC_CXX_VERSION"
}

# Resolve package variables
rmc_yaml_resolve() {
    rmc_boost_check
    rmc_resolve_root_and_version yaml
    rmc_add_library_path yaml lib
}

# Check that package is installed
rmc_yaml_check() {
    rmc_yaml_resolve
    rmc_check_root_and_version yaml
}
