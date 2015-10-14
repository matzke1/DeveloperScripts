# C++ compiler
#
# usage: rmc_compiler VENDOR VERSION [LANG]
#        rmc_compiler VENDOR-VERSION
#        rmc_compiler NAME
#
# Vendors are:
#        gcc      - GCC compilers
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
		gcc)
		    RMC_CXX_VENDOR="$vendor"
		    RMC_CXX_VERSION="$version"
		    RMC_CXX_NAME=
		    ;;
	    esac
	fi
    fi

    # Default compiler if none specified
    if [ "$RMC_CXX_NAME" = "" -a "$RMC_CXX_VENDOR" = "" -a "$RMC_CXX_VERSION" = "" ]; then
	RMC_CXX_NAME=g++
    fi

    if [ "$RMC_CXX_VENDOR" = "" -o "$RMC_CXX_VERSION" = "" ]; then
        # Get the vendor and version information from the compiler name, which must be specified
        if [ "$RMC_CXX_NAME" = "" ]; then
            echo "$arg0: either a compiler name or vendor+version must be specified" >&2
            exit 1
        fi
        local cxx_realname=$(which "$RMC_CXX_NAME")
        if [ "$cxx_realname" = "" ]; then
            echo "$arg0: no such compiler command in path: $RMC_CXX_NAME" >&2
            exit 1
        fi

	if [ "$RMC_CXX_VENDOR" = "" ]; then
	    if "$cxx_realname" --version |grep 'Free Software Foundation' >/dev/null; then
		RMC_CXX_VENDOR="gcc"
	    else
		echo "$arg0: cannot determine compiler vendor for $cxx_realname" >&2
		exit 1
	    fi
	fi

        if [ "$RMC_CXX_VERSION" = "" ]; then
            RMC_CXX_VERSION=$("$cxx_realname" --version |\
                              head -n1 |\
                              perl -ne '/(\d+(\.\d+){1,2})$/ && print $1')
            if [ "$RMC_CXX_VERSION" = "" ]; then
                echo "$arg0: cannot obtain compiler version number from $cxx_realname" >&2
                exit 1
            fi
        fi
    fi

    if [ "$RMC_CXX_NAME" = "" ]; then
	# Build a name from the vendor and version info, which we know are set
	if [ "$RMC_CXX_VENDOR" = "gcc" ]; then
	    RMC_CXX_NAME="g++-$RMC_CXX_VERSION"
	else
	    echo "$arg0: cannot find $RMC_CXX_VENDOR C++ compiler version $RMC_CXX_VERSION" >&2
	    exit 1
        fi

	local cxx_realname=$(which $RMC_CXX_NAME)
	if [ "$cxx_realname" = "" ]; then
	    echo "$arg0: no such compiler in path: $RMC_CXX_NAME" >&2
	    exit 1
	fi
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
