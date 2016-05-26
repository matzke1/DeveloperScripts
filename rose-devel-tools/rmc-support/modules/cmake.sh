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
    echo "$base/$vers/$RMC_CXX_VENDOR-$RMC_CXX_VERSION-$RMC_CXX_LANGUAGE/$RMC_OS_NAME_FILE"
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
    rmc_compiler_check
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

    if [ "$vers" = "system" -o "$vers" = "no" -o "$vers" = "none" -o "$vers" = "ambivalent" ]; then
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
    case "$RMC_OPTIM" in
	yes)
            if [ "$RMC_DEBUG" = "yes" ]; then
		echo "$arg0: cmake builds cannot handle optimize + debug" >&2
		exit 1
	    else
		cmake_build_type="-DCMAKE_BUILD_TYPE=Release"
            fi
	    ;;
	no)
	    if [ "$RMC_DEBUG" = "yes" ]; then
		cmake_build_type="-DCMAKE_BUILD_TYPE=Debug"
	    else
		echo "$arg0: cmake builds cannot handle non-optimized + non-debug" >&2
		exit 1
	    fi
	    ;;
	ambivalent)
	    cmake_build_type=
	    ;;
	*)
            echo "$arg0: cmake builds cannot handle optimize = $RMC_OPTIM" >&2
	    exit 1
	    ;;
    esac

    # CMake is not fully supported yet
    echo "$arg0: warning: cmake configuration is not fully implemented; it might not honor some settings" >&2
    if [ "$dry_run" = "" ]; then
	echo "$arg0: warning: I assume you've carefully checked the output from --dry-run already!" >&2
    fi

    (
        set -e
        cd "$RMC_ROSEBLD_ROOT"
        rmc_execute $dry_run "$RMC_CMAKE_FILE" "$RMC_ROSESRC_ROOT" \
            $cmake_build_type \
	    -DCMAKE_CXX_COMPILER="$RMC_CXX_NAME" \
	    -DCMAKE_CXX_FLAGS="$RMC_CXX_SWITCHES" \
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

# List installed versions
rmc_cmake_list() {
    local base="$1"
    local link
    for link in $(cd "$base" && find . -maxdepth 3 -type l |sort); do
	if [ -e "$base/$link/bin/cmake" ]; then
	    local version=$(echo "$link" |cut -d/ -f2)
	    local compiler=$(echo "$link" |cut -d/ -f3)
	    local os=$(echo "$link" |cut -d/ -f4)
	    local dir=$(cd "$base" && readlink "$link")
	    local date=$(echo "$dir" |sed 's/.*\([0-9][0-9][0-9][0-9]\)\([0-9][0-9]\)\([0-9][0-9]\)$/\1-\2-\3/')
	    echo "RMC_CMAKE_VERSION='$version' RMC_CXX_NAME='$compiler' RMC_OS_NAME='$os' DATE='$date'"
	fi
    done
}
