# C++ compiler
#
# usage: rmc_compiler VENDOR VERSION [LANG]
#        rmc_compiler VENDOR-VERSION[-LANG]
#        rmc_compiler NAME
#
# Vendors are:
#        gcc      - GCC compilers (e.g., g++)
#        llvm     - LLVM compilers (e.g., clang++)
#
export RMC_CXX_VENDOR		# 'gcc', 'llvm', etc.
export RMC_CXX_VERSION		# version number
export RMC_CXX_LANGUAGE		# empty, 'c++11', etc.
export RMC_CXX_NAME		# the name of the executable (no arguments)
export RMC_CXX_SWITCHES		# extra switches needed to run the compiler (like "-std=c++11")

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
    rmc_os_resolve
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
		gcc|llvm)
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
    # first. Eventually we scan the list too find the first name that matches.
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
	    "")
		cxx_vendor_basename="c++"
		;;
	    *)
		echo "$arg0: name of $RMC_CXX_VENDOR C++ compiler is unknown" >&2
		exit 1
		;;
	esac
	local cxx_command_list="$cxx_vendor_basename"

	# More specifically, append the specified version number
	if [ "$RMC_CXX_VERSION" != "" ]; then
	    cxx_command_list="$cxx_vendor_basename-$RMC_CXX_VERSION $cxx_command_list"
	fi

	# Look for compiler commands in the RMC toolchain but use all the directories that start with the same
	# version. The toolchain stores the full version number, like "4.8.4", but we might have only the major and
	# minor numbers given to us in $RMC_CXX_VERSION.
	if [ -d "$RMC_RMC_TOOLCHAIN/compiler/." ]; then
	    local d f
	    for d in $(find "$RMC_RMC_TOOLCHAIN/compiler" -maxdepth 1 -name "$RMC_CXX_VENDOR-$RMC_CXX_VERSION.*" |sort); do
		f="$d/$RMC_OS_NAME_FILE/bin/$cxx_vendor_basename"
		cxx_command_list="$f $cxx_command_list" # latest alphabetically will be first in list
	    done
	    f="$RMC_RMC_TOOLCHAIN/compiler/$RMC_CXX_VENDOR-$RMC_CXX_VERSION/$RMC_OS_NAME_FILE/bin/$cxx_vendor_basename"
	    cxx_command_list="$f $cxx_command_list"
	fi

	# Search our list of possible commands until we find one that exists. Therefore the list should have been
	# sorted already from best possible match to most general match.
	for RMC_CXX_NAME in $cxx_command_list; do
	    if [ "$(which $RMC_CXX_NAME 2>/dev/null)" != "" ]; then
		break
	    fi
	done

	if [ "$RMC_CXX_NAME" = "" ]; then
	    echo "$arg0: cannot find $RMC_CXX_VENDOR $RMC_CXX_VERSION C++ compiler command" >&2
	    exit 1
	fi
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

    # Extra compiler switches for various things.
    local del_switches=() add_switches=()

    # Switches affecting the language
    export RMC_CXX_SWITCHES_LANGUAGE
    if [ "$RMC_CXX_LANGUAGE" != "default" ]; then
	case "$RMC_CXX_VENDOR" in
	    gcc|llvm)
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
	gcc|llvm)
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
    if [ "$RMC_OPTIM" != "no" -a "$RMC_OPTIM" != "yes" ]; then
	echo "$arg0: not sure what RMC_OPTIM=$RMC_OPTIM means" >&2
	exit 1
    fi
    case "$RMC_CXX_VENDOR" in
	gcc|llvm)
	    if [ "$RMC_OPTIM" = "no" ]; then
		RMC_CXX_SWITCHES_OPTIM="-O0"
		del_switches=("${del_switches[@]}" "-O" "-O1" "-O2" "-O3" "-Os" "-Og" "-Ofast" "-fomit-frame-pointer")
		add_switches=("${add_switches[@]}" "-O0")
	    else
		RMC_CXX_SWITCHES_OPTIM="-O3 -fomit-frame-pointer"
		del_switches=("${del_switches[@]}" "-O" "-O0" "-O1" "-O2" "-Os" "-Og" "-Ofast")
		add_switches=("${add_switches[@]}" "-O3" "-fomit-frame-pointer")
	    fi
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
	llvm)
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
	    echo "$arg0: not sure how to specify code coverage for $RMC_CXX_VENDOR compiler" >&2
	    exit 1
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
