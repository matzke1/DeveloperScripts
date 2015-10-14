# Build system
#
# usage: rmc_build autoconf|cmake
#
export RMC_BUILD_SYSTEM

rmc_build() {
    RMC_BUILD_SYSTEM="$1"
}

rmc_build_resolve() {
    case "$RMC_BUILD_SYSTEM" in
	"")
	    RMC_BUILD_SYSTEM=autoconf
	    ;;
	autoconf|cmake)
	    ;;
	*)
	    echo "$arg0: invalid build system: $RMC_BUILD_SYSTEM" >&2
	    exit 1
	    ;;
    esac
}

rmc_build_check() {
    rmc_build_resolve
    case "$RMC_BUILD_SYSTEM" in
	autoconf)
	    rmc_autoconf_check
	    ;;
	cmake)
	    rmc_cmake_check
	    ;;
	*)
	    echo "$arg0: invalid build system: $RMC_BUILD_SYSTEM" >&2
	    exit 1
	    ;;
    esac
}
