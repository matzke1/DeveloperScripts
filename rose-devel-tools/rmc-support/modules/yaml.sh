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
    echo "$base/$vers/boost-$RMC_BOOST_VERSION/$RMC_CXX_VENDOR-$RMC_CXX_VERSION-$RMC_CXX_LANGUAGE"
}

# Find canonical installed file for package
rmc_yaml_file() {
    local root="$1"
    local file="$root/include/yaml-cpp/yaml.h"
    [ -r "$file" ] && echo "$file"
}

# Find installation root in filesystem
rmc_yaml_find_in_system() {
    : not implemented
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

# List installed versions
rmc_yaml_list() {
    local base="$1"
    local link
    for link in $(cd "$base" && find . -maxdepth 3 -type l |sort); do
	if [ -d "$base/$link/lib/." ]; then
	    local version=$(echo "$link" |cut -d/ -f2)
	    local boost=$(echo "$link" |cut -d/ -f3)
	    local compiler=$(echo "$link" |cut -d/ -f4)
	    local dir=$(cd "$base" && readlink "$link")
	    local date=$(echo "$dir" |sed 's/.*\([0-9][0-9][0-9][0-9]\)\([0-9][0-9]\)\([0-9][0-9]\)$/\1-\2-\3/')
	    echo "RMC_YAML_VERSION='$version' RMC_BOOST_VERSION='$boost' RMC_CXX_NAME='$compiler' DATE='$date'"
	fi
    done
}
