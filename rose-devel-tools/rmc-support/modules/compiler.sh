# C++ compiler
#
# usage: rmc_compiler VENDOR VERSION [LANG]
#        rmc_compiler VENDOR-VERSION
#        rmc_compiler NAME
#
# Vendors are:
#        gcc      - GCC compilers (e.g., g++)
#        llvm     - LLVM compilers (e.g., clang++)
#
export RMC_CXX_VENDOR
export RMC_CXX_VERSION
export RMC_CXX_LANGUAGE
export RMC_CXX_NAME
rmc_compiler() {
    if [ "$#" -eq 1 ]; then
        RMC_CXX_VENDOR=
        RMC_CXX_VERSION=
        RMC_CXX_LANGUAGE=
        RMC_CXX_NAME="$1"
    else
        RMC_CXX_VENDOR="$1"
        RMC_CXX_VERSION="$2"
        RMC_CXX_LANGUAGE="$3"
        RMC_CXX_NAME=
    fi
}

# Resolve compiler variables
rmc_compiler_resolve() {

    # If it looks like the user said something like "rmc_compiler gcc-4.8.4", then split the
    # name apart into vendor and version instead.
    if [ "$RMC_CXX_VENDOR" = "" -a "$RMC_CXX_VERSION" = "" ]; then
	local vendor=$(echo "$RMC_CXX_NAME" |cut -d- -f1)
	local version=$(echo "$RMC_CXX_NAME" |cut -d- -f2)
	if rmc_is_version_string "$version"; then
	    case "$vendor" in
		gcc|llvm)
		    RMC_CXX_VENDOR="$vendor"
		    RMC_CXX_VERSION="$version"
		    RMC_CXX_NAME=
		    ;;
	    esac
	fi
    fi

    # Find a default compiler if none was specified.
    local cxx_vendor_commands
    if [ "$RMC_CXX_NAME" = "" ]; then
	case "$RMC_CXX_VENDOR" in
	    gcc)
		cxx_vendor_commands="g++"
		;;
	    llvm)
		cxx_vendor_commands="clang++"
		;;
	    "")
		cxx_vendor_commands="c++"
		;;
	    *)
		echo "$arg0: name of $RMC_CXX_VENDOR C++ compiler is unknown" >&2
		exit 1
		;;
	esac
	if [ "$RMC_CXX_VERSION" != "" ]; then
	    cxx_vendor_commands="$cxx_vendor_commands-$RMC_CXX_VERSION $cxx_vendor_commands"
	fi

	for RMC_CXX_NAME in $cxx_vendor_commands; do
	    if [ "$(which $RMC_CXX_NAME)" != "" ]; then
		break
	    fi
	done

	if [ "$RMC_CXX_NAME" = "" ]; then
	    echo "$arg0: cannot find $RMC_CXX_VENDOR $RMC_CXX_VERSION C++ compiler command" >&2
	    exit 1
	fi
    fi

    # If we have a compiler command name, then try to obtain a vendor and version from the command
    local cxx_vendor= cxx_version=
    if [ "$RMC_CXX_NAME" != "" ]; then
        local cxx_realname=$(which "$RMC_CXX_NAME")
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
    fi

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
}

# Check existence
rmc_compiler_check() {
    rmc_compiler_resolve
    if [ "$RMC_CXX_NAME" = "" -o "$RMC_CXX_VENDOR" = "" -o "$RMC_CXX_VERSION" = "" ]; then
	echo "$arg0: a C++ compiler is required" >&2
	exit 1
    fi
}
