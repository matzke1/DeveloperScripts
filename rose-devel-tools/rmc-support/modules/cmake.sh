# cmake executable
#
# usage: rmc_cmake VERSION [BASE]
#    or: rmc_cmake DIRECTORY
#    or: rmc_cmake system (or "yes")
#    or: rmc_cmake no
#
export RMC_CMAKE_BASEDIR
export RMC_CMAKE_VERSION
export RMC_CMAKE_ROOT
export RMC_CMAKE_FILE

rmc_cmake() {
    rmc_parse_version_or file cmake "$@"
}

# Obtain a version number from an installed package
rmc_cmake_version() {
    local root="$1"
    local output=$("$root/cmake" --version 2>&1 |head -n1)
    perl -e '$ARGV[0] =~ /(\d+(\.\d+)+)/ && print $1' "$output"
}

# Obtain an installation directory name from a version. Directory need not exist.
rmc_cmake_root() {
    local base="$1" vers="$2"
    echo "$base/$vers"
}

# Find file in installed package.
rmc_cmake_file() {
    local root="$1"
    local try
    for try in bin/cmake cmake; do
	if [ ! -d "$root/$try" -a -r "$root/$try" ]; then
	    echo "$root/$try"
	    return 0
	fi
    done
}

# Resolve package variables
rmc_cmake_resolve() {
    rmc_resolve_root_and_version cmake
}

# Find executable for "system" version
rmc_cmake_find_in_system() {
    which cmake
}

# Check that package is installed
rmc_cmake_check() {
    rmc_cmake_resolve
    rmc_check_root_and_version cmake
}

# Generate optional cmake "-D..._ROOT=..." argument for a package.
rmc_cmake_define() {
    local pkg="$1" switch_name="$2" subname="$3"
    local pkguc=$(echo "$pkg" |tr a-z A-Z)
    [ "$switch_name" = "" ] && switch_name="$pkguc"
    local root=$(eval echo '$RMC_'$pkguc'_ROOT')
    local vers=$(eval echo '$RMC_'$pkguc'_VERSION')

    if [ "$vers" = "system" -o "$vers" = "no" -o "$vers" = "none" ]; then
	: nothing
    elif [ "$root" != "" ]; then
        echo "-D${switch_name}_ROOT=$(rmc_find_root "$pkguc" "$pkg" "$subname")"
    else
	: nothing
    fi
}

# Run the "cmake" command
rmc_cmake_run() {
    local dry_run="$1"

    local cmake_build_type
    if [ "$RMC_OPTIM" = "yes" ]; then
        if [ "$RMC_DEBUG" = "yes" ]; then
            echo "$arg0: warning: cmake builds cannot handle optimize+debug (assuming \"Release\" build type)" >&2
        fi
        cmake_build_type="Release"
    elif [ "$RMC_DEBUG" = "yes" ]; then
        cmake_build_type="Debug"
    else
        echo "$arg0: warning: camek builds cannot handle nonoptimize+nondebug (assuming \"Debug\" build type)" >&2
        cmake_build_type="Debug"
    fi

    (
        set -e
        cd "$RMC_ROSEBLD_ROOT"
        rmc_execute $dry_run "$RMC_CMAKE_FILE" "$RMC_ROSESRC_ROOT" \
            -DCMAKE_BUILD_TYPE="$cmake_build_type" \
            -DCMAKE_INSTALL_PREFIX="$RMC_INSTALL_ROOT" \
            -DASSERTION_BEHAVIOR="$RMC_ASSERTIONS" \
            $(rmc_cmake_define boost) \
            $(rmc_cmake_define dlib) \
            $(rmc_cmake_define doxygen DOXYGEN bin/doxygen) \
            -DEDG_VERSION="$RMC_EDG_VERSION" \
            $(rmc_cmake_define readline) \
            $(rmc_cmake_define magic) \
            $(rmc_cmake_define sqlite) \
            $(rmc_cmake_define yaml) \
            $(rmc_cmake_define yices) \
            $(rmc_cmake_define wt) \
            -Denable-cuda:BOOL=OFF
    )
}
