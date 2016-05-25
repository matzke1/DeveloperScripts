# C++ compiler
#
# usage: rmc_compiler VENDOR VERSION [LANG]
#        rmc_compiler VENDOR-VERSION[-LANG]
#        rmc_compiler NAME
#
# Vendors are:
#        gcc      - GCC compilers (e.g., g++)
#        llvm     - LLVM compilers (e.g., clang++)
#        intel    - Intel compilers (e.g., icpc)
#
export RMC_CXX_VENDOR		# 'gcc', 'llvm', 'intel'.
export RMC_CXX_VERSION		# version number
export RMC_CXX_LANGUAGE		# empty, 'c++11', etc.
export RMC_CXX_NAME		# the name of the executable (no arguments)
export RMC_CXX_SWITCHES		# extra switches needed to run the compiler (like "-std=c++11")
export RMC_CXX_LIBDIRS		# colon-separated libraries needed by this compiler
export RMC_FORTRAN_NAME         # name of fortran compiler

rmc_compiler() {
    if [ "$#" -eq 1 ]; then
        RMC_CXX_VENDOR=
        RMC_CXX_VERSION=
        RMC_CXX_LANGUAGE=
        RMC_CXX_NAME="$1"
	RMC_CXX_COMMAND="$1"
    else
        RMC_CXX_VENDOR="$1"
        RMC_CXX_VERSION="$2"
        RMC_CXX_LANGUAGE="$3"
        RMC_CXX_NAME=
	RMC_CXX_COMMAND=
    fi
}

# Resolve compiler variables
rmc_compiler_resolve() {
    rmc_os_check
    rmc_code_coverage_resolve
    rmc_debug_resolve
    rmc_optim_resolve
    rmc_warnings_resolve

    # If it looks like the user said something like "rmc_compiler gcc-4.8.4[-c++11]", then split the
    # name apart into vendor, version, and language instead.
    if [ "$RMC_CXX_VENDOR" = "" -a "$RMC_CXX_VERSION" = "" ]; then
	local vendor=$(echo "$RMC_CXX_NAME" |cut -d- -f1)
	local version=$(echo "$RMC_CXX_NAME" |cut -d- -f2)
	local language=$(echo "$RMC_CXX_NAME" |cut -d- -f3-)
	if rmc_is_version_string "$version"; then
	    case "$vendor" in
		gcc|llvm|intel)
		    RMC_CXX_VENDOR="$vendor"
		    RMC_CXX_VERSION="$version"
		    RMC_CXX_LANGUAGE="$language"
		    RMC_CXX_NAME=
		    RMC_CXX_COMMAND=
		    ;;
	    esac
	fi
    fi
    [ "$RMC_CXX_LANGUAGE" = "" ] && RMC_CXX_LANGUAGE=default

    # Find a default compiler if none was specified.  We start with the basic compiler name, like "g++" and then build a list
    # of possible names by adding version numbers, directories, etc.  The list is sorted so that the most specific names are
    # first. Eventually we scan the list to find the first name that matches.
    if [ "$RMC_CXX_NAME" = "" ]; then
	# Start with the most basic names, like "g++"
	local cxx_vendor_basename=
	case "$RMC_CXX_VENDOR" in
	    gcc)
		cxx_vendor_basename="g++"
		;;
	    llvm)
		cxx_vendor_basename="clang++"
		;;
	    intel)
		cxx_vendor_basename="icpc"
		;;
	    "")
		cxx_vendor_basename="c++"
		;;
	    *)
		echo "$arg0: name of $RMC_CXX_VENDOR C++ compiler is unknown" >&2
		exit 1
		;;
	esac

	# Look for compiler commands in the RMC toolchain but use all the directories that start with the same
	# version. The toolchain stores the full version number, like "4.8.4", but we might have only the major and
	# minor numbers given to us in $RMC_CXX_VERSION.
	if [ -d "$RMC_RMC_TOOLCHAIN/compiler/." ]; then
	    local d
	    for d in $(find "$RMC_RMC_TOOLCHAIN/compiler" -maxdepth 1 -name "$RMC_CXX_VENDOR-$RMC_CXX_VERSION*" |sort -r); do
		local f="$d/$RMC_OS_NAME_FILE/bin/$cxx_vendor_basename"
		if [ -e "$f" ]; then
		    RMC_CXX_NAME="$f"
		    break
		fi
	    done
	fi

	# See if the base name with version is in the PATH
	local f="$cxx_vendor_basename-$RMC_CXX_VERSION"
	if [ "$RMC_CXX_NAME" = "" -a "$(which $f 2>/dev/null)" != "" ]; then
	    RMC_CXX_NAME="$f"
	fi

	# See if spack is installed and knows about this compiler
	if [ "$RMC_CXX_NAME" = "" ]; then
	    local best_spec=$(rmc_spack find "$RMC_CXX_VENDOR" |\
				     grep "^$RMC_CXX_VENDOR@$RMC_CXX_VERSION" |\
				     cut -d+ -f1 |\
				     sort -r |\
				     head -n1)
	    if [ "$best_spec" != "" ]; then
		local spack_prefix=$(rmc_spack_prefix "$best_spec")
		f="$spack_prefix/bin/$cxx_vendor_basename"
		if [ -e "$f" ]; then
		    RMC_CXX_NAME="$f"
		fi
	    fi
	fi
		
	# See if the base name by itself is in the PATH
	if [ "$RMC_CXX_NAME" = "" -a "$(which $cxx_vendor_basename 2>/dev/null)" != "" ]; then
	    RMC_CXX_NAME="$cxx_vendor_basename"
	fi

	if [ "$RMC_CXX_NAME" = "" ]; then
	    echo "$arg0: cannot find $RMC_CXX_VENDOR $RMC_CXX_VERSION C++ compiler command" >&2
	    exit 1
	fi
    fi

    # Where is the root for this compiler installation?
    local cxx_command_root=
    if [ "${RMC_CXX_NAME%/bin/*}" != "$RMC_CXX_NAME" ]; then
	cxx_command_root="${RMC_CXX_NAME%/bin/*}"
    elif [ "${RMC_CXX_NAME%/bin/intel64/*}" != "$RMC_CXX_NAME" ]; then
	cxx_command_root="${RMC_CXX_NAME%/bin/intel64/*}"
    fi

    # Some compilers also have shared libraries that need to be in the library search path.
    if [ "$cxx_command_root" != "" ]; then
	[ -d "$cxx_command_root/lib/." ] && \
	    RMC_CXX_LIBDIRS=$(rmc_adjust_list prepend_or_move "$cxx_command_root/lib" : "$RMC_CXX_LIBDIRS")
	[ -d "$cxx_command_root/lib64/." ] && \
	    RMC_CXX_LIBDIRS=$(rmc_adjust_list prepend_or_move "$cxx_command_root/lib64" : "$RMC_CXX_LIBDIRS")
    fi
    if [ "$RMC_CXX_VENDOR" = "intel" ]; then
	local script="$RMC_RMC_TOOLCHAIN/compiler/$RMC_CXX_VENDOR-$RMC_CXX_VERSION/$RMC_OS_NAME_FILE/bin/iccvars.sh"
	if [ ! -e "$script" ]; then
	    echo "$arg0: intel compiler script not found: $script" >&2
	    exit 1
	fi
	local dirs=$(source "$script" intel64; echo "$LD_LIBRARY_PATH")
	RMC_CXX_LIBDIRS=$(rmc_adjust_list prepend_or_move "$dirs" : "$RMC_CXX_LIBDIRS")
    fi

    # Try to obtain a vendor and version from the command
    local cxx_vendor= cxx_version=
    local cxx_realname=$(which "$RMC_CXX_NAME" 2>/dev/null)
    if [ "$cxx_realname" = "" ]; then
	echo "$arg0: no such compiler command in path: $RMC_CXX_NAME" >&2
	exit 1
    fi

    if "$cxx_realname" --version 2>&1 |grep 'Free Software Foundation' >/dev/null; then
	cxx_vendor="gcc"
    elif "$cxx_realname" --version 2>&1 |grep 'based on LLVM' >/dev/null; then
	cxx_vendor="llvm"
    elif "$cxx_realname" --version 2>&1 |grep 'Intel Corporation' >/dev/null; then
	cxx_vendor="intel"
    else
	: need to figure out how to get this info
    fi

    cxx_version=$("$cxx_realname" --version |\
		   head -n1 |\
		   perl -ne '/(\d+(\.\d+){2,3})/ && print $1')

    # Double check the user-supplied vendor/version info, or use the info we found above.  If the user specified
    # "4.9" and the version reported by the compiler is "4.9.2" that's okay.
    if [ "$RMC_CXX_VENDOR" = "" ]; then
	RMC_CXX_VENDOR="$cxx_vendor"
    elif [ "$RMC_CXX_VENDOR" != "$cxx_vendor" -a "$cxx_vendor" != "" ]; then
	echo "$arg0: compiler vendor mismatch (expected $RMC_CXX_VENDOR but got $cxx_vendor)" >&2
	exit 1
    fi
    if [ "$RMC_CXX_VERSION" = "" ]; then
	RMC_CXX_VERSION="$cxx_version"
    elif [ "$cxx_version" = "" -o "$cxx_version" = "$RMC_CXX_VERSION" ]; then
	: okay
    elif [ "${cxx_version#$RMC_CXX_VERSION.}" = "$cxx_version" ]; then
	echo "$arg0: compiler version mismatch for $RMC_CXX_NAME (expected $RMC_CXX_VERSION but got $cxx_version)" >&2
	exit 1
    else
	RMC_CXX_VERSION="$cxx_version"
    fi

    # Fortran compiler if none specified yet.
    if [ "$RMC_FORTRAN_NAME" = "" ]; then
	local fortran_dir=$(which "$cxx_realname")
	fortran_dir="${cxx_realname%/*}"
	local fortran_base=$(basename $cxx_realname)
	if [ "$fortran_dir" != "" ]; then
	    case "$RMC_CXX_VENDOR" in
		gcc)
		    fortran_base=$(echo "$fortran_base" |sed 's/g++/gfortran/')
		    ;;
		llvm)
		    fortran_base=gfortran
		    ;;
		intel)
		    fortran_base=$(echo "$fortran_base" |sed 's/icpc/ifort/')
		    ;;
		*)
		    fortran_base=
		    ;;
	    esac
	fi

	if [ "$fortran_base" = "" ]; then
	    : no fortran
	elif [ -e "$fortran_dir/$fortran_base" ]; then
	    RMC_FORTRAN_NAME="$fortran_dir/$fortran_base"
	elif [ -e $(which "$fortran_base" 2>/dev/null) ]; then
	    RMC_FORTRAN_NAME=$(which "$fortran_base" 2>/dev/null)
	fi
    fi

    # Extra compiler switches for various things.
    local del_switches=() add_switches=()

    # Switches affecting the language
    export RMC_CXX_SWITCHES_LANGUAGE
    if [ "$RMC_CXX_LANGUAGE" != "default" ]; then
	case "$RMC_CXX_VENDOR" in
	    gcc|llvm|intel)
		RMC_CXX_SWITCHES_LANGUAGE="-std=$RMC_CXX_LANGUAGE"
		add_switches=("${add_switches[@]}" "-std=$RMC_CXX_LANGUAGE")
		;;
	    *)
		echo "$arg0: not sure how to specify \"$RMC_CXX_LANGUAGE\" to $RMC_CXX_VENDOR compiler" >&2
		exit 1
		;;
	esac
    fi

    # Switches affecting debugging
    export RMC_CXX_SWITCHES_DEBUG
    if [ "$RMC_DEBUG" != "no" -a "$RMC_DEBUG" != "yes" ]; then
	echo "$arg0: not sure what RMC_DEBUG=$RMC_DEBUG means" >&2
	exit 1
    fi
    case "$RMC_CXX_VENDOR" in
	gcc|llvm|intel)
	    if [ "$RMC_DEBUG" = "no" ]; then
		del_switches=("${del_switches[@]}" "-g")
	    else
		RMC_CXX_SWITCHES_DEBUG="-g"
		add_switches=("${add_switches[@]}" "-g")
	    fi
	    ;;
	*)
	    echo "$arg0: not sure how to specify debugging for $RMC_CXX_VENDOR compiler" >&2
	    exit 1
	    ;;
    esac

    # Switches affecting optimization
    export RMC_CXX_SWITCHES_OPTIM
    case "$RMC_CXX_VENDOR" in
	gcc|llvm|intel)
	    case "$RMC_OPTIM" in
		yes)
		    RMC_CXX_SWITCHES_OPTIM="-O3 -fomit-frame-pointer"
		    del_switches=("${del_switches[@]}" "-O" "-O0" "-O1" "-O2" "-Os" "-Og" "-Ofast")
		    add_switches=("${add_switches[@]}" "-O3" "-fomit-frame-pointer")
		    ;;
		no)
		    RMC_CXX_SWITCHES_OPTIM="-O0"
		    del_switches=("${del_switches[@]}" "-O" "-O1" "-O2" "-O3" "-Os" "-Og" "-Ofast" "-fomit-frame-pointer")
		    add_switches=("${add_switches[@]}" "-O0")
		    ;;
		ambivalent)
		    : no changes
		    ;;
		*)
		    echo "$arg0: optimization level $RMC_OPTIM is not handled for $RMC_CXX_VENDOR compiler" >&2
		    exit 1
		    ;;
	    esac
	    ;;
	*)
	    echo "$arg0: not sure how to specify optimization level for $RMC_CXX_VENDOR compiler" >&2
	    exit 1
	    ;;
    esac

    # Switches affecting reporting of warnings
    export RMC_CXX_SWITCHES_WARN
    if [ "$RMC_WARNINGS" != "no" -a "$RMC_WARNINGS" != "yes" ]; then
	echo "$arg0: not sure what RMC_WARNINGS=$RMC_WARNINGS means" >&2
	exit 1
    fi
    case "$RMC_CXX_VENDOR" in
	gcc)
	    if [ "$RMC_WARNINGS" = "no" ]; then
		del_switches=("${del_switches[@]}" "-Wall" "-Wno-unused-local-typedefs" "-Wno-attributes")
	    else
		RMC_CXX_SWITCHES_WARN="-Wall"
		add_switches=("${add_switches[@]}" "-Wall")
		if rmc_versions_ordered "$RMC_CXX_VERSION" ge "4.8.0"; then
		    RMC_CXX_SWITCHES_WARN="$RMC_CXX_SWITCHES_WARN -Wno-unused-local-typedefs -Wno-attributes"
		    add_switches=("${add_switches[@]}" "-Wno-unused-local-typedefs" "-Wno-attributes")
		fi
	    fi
	    ;;
	llvm|intel)
	    if [ "$RMC_WARNINGS" = "no" ]; then
		del_switches=("${del_switches[@]}" "-Wall")
	    else
		add_switches=("${add_switches[@]}" "-Wall")
	    fi
	    ;;
	*)
	    echo "$arg0: not sure how to specify warnings for $RMC_CXX_VENDOR compiler" >&2
	    exit 1
	    ;;
    esac

    # Switches affecting code coverage analysis
    export RMC_CXX_SWITCHES_COVERAGE
    if [ "$RMC_CODE_COVERAGE" != "no" -a "$RMC_CODE_COVERAGE" != "yes" ]; then
	echo "$arg0: not sure what RMC_CODE_COVERAGE=$RMC_CODE_COVERAGE means" >&2
	exit 1
    fi
    case "$RMC_CXX_VENDOR" in
	gcc|llvm)
	    if [ "$RMC_CODE_COVERAGE" = "no" ]; then
		del_switches=("${del_switches[@]}" "-fprofile-arcs" "-ftest-coverage")
	    else
		RMC_CXX_SWITCHES_COVERAGE="-fprofile-arcs -ftest-coverage"
		add_switches=("${add_switches[@]}" "-fprofile-arcs" "-ftest-coverage")
	    fi
	    ;;
	*)
	    if [ "$RMC_CODE_COVERAGE" != "no" ]; then
		echo "$arg0: not sure how to specify code coverage for $RMC_CXX_VENDOR compiler" >&2
		exit 1
	    fi
	    ;;
    esac

    # Update the list of all switches based on what needs to be deleted and added.
    local switch
    for switch in "${del_switches[@]}"; do
	RMC_CXX_SWITCHES=$(rmc_adjust_switches erase "$switch" $RMC_CXX_SWITCHES)
    done
    for switch in "${add_switches[@]}"; do
	RMC_CXX_SWITCHES=$(rmc_adjust_switches insert "$switch" $RMC_CXX_SWITCHES)
    done
}

# Check existence
rmc_compiler_check() {
    rmc_code_coverage_check
    rmc_compiler_resolve
    if [ "$RMC_CXX_NAME" = "" -o "$RMC_CXX_VENDOR" = "" -o "$RMC_CXX_VERSION" = "" ]; then
	echo "$arg0: a C++ compiler is required" >&2
	exit 1
    fi
}

# List installed compilers
rmc_compiler_list() {
    local base="$1"
    local dir
    # Look for the "bin" directory because we don't actually know the name of the compiler without knowing a bunch
    # of other stuff too.
    for dir in $(cd "$base" && find . -follow -maxdepth 3 -name bin -type d |sort); do
	local version=$(echo "$dir" |cut -d/ -f2)
	local os=$(echo "$dir" |cut -d/ -f3)
	echo "RMC_COMPILER_NAME='$version' RMC_OS_NAME='$os'"
    done
}
