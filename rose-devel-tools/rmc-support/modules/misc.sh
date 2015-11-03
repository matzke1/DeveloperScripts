# Installation prefix.
#
# usage: rmc_install yes|no|DIRECTORY
#
# If DIRECTORY is relative then it will be relative to the top of the build
# directory.  A value of "no" means "make install" will probably fail. A
# value of yes just uses the default.
export RMC_INSTALL_ROOT
rmc_install() {
    RMC_INSTALL_ROOT="$1"
}

rmc_install_resolve() {
    rmc_rosebld_check
    case "$RMC_INSTALL_ROOT" in
        ""|yes)
            RMC_INSTALL_ROOT="$RMC_ROSEBLD_ROOT/installed"
            ;;
        no)
            RMC_INSTALL_ROOT="/DO_NOT_INSTALL"
            ;;
        *)
            RMC_INSTALL_ROOT=$(cd "$RMC_ROSEBLD_ROOT" && rmc_realpath "$RMC_INSTALL_ROOT")
            ;;
    esac
}

rmc_install_check() {
    rmc_install_resolve
}

# What frontend languages to support
#
# usage: rmc_languages all|COMMA_SEPARATED_LIST
#
export RMC_LANGUAGES
rmc_languages() {
    RMC_LANGUAGES="$1"
}

rmc_languages_resolve() {
    if [ "$RMC_LANGUAGES" = "" ]; then
	RMC_LANGUAGES=all
    fi
}

rmc_languages_check() {
    rmc_languages_resolve
}

# Debugging support
#
# usage: rmc_debug yes|no
#
export RMC_DEBUG
rmc_debug() {
    RMC_DEBUG="$1"
}

rmc_debug_resolve() {
    case "$RMC_DEBUG" in
	"")
	    RMC_DEBUG=yes
	    ;;
	yes|no)
	    ;;
	*)
	    echo "$arg0: invalid debug mode: $RMC_DEBUG" >&2
	    exit 1
	    ;;
    esac
}

rmc_debug_check() {
    rmc_debug_resolve
}

# Compiler warnings. Turn on compiler warnings.
#
# usage: rmc_warnings yes|no
#
export RMC_WARNINGS
rmc_warnings() {
    RMC_WARNINGS="$1"
}

rmc_warnings_resolve() {
    case "$RMC_WARNINGS" in
	"")
	    RMC_WARNINGS=yes
	    ;;
	yes|no)
	    ;;
	*)
	    echo "$arg0: invalid warning mode: $RMC_WARNINGS" >&2
	    exit 1
	    ;;
    esac
}

rmc_warnings_check() {
    rmc_warnings_resolve
}

# Optimization
#
# usage: rmc_optimize yes|no
#
export RMC_OPTIM
rmc_optimize() {
    RMC_OPTIM="$1"
}

rmc_optim_resolve() {
    case "$RMC_OPTIM" in
	"")
	    RMC_OPTIM=yes
	    ;;
	yes|no)
	    ;;
	*)
	    echo "$arg0: invalid optimaization mode: $RMC_OPTIM" >&2
	    exit 1
	    ;;
    esac
}

rmc_optim_check() {
    rmc_optim_resolve
}

# Failure mode for assertions (Sawyer ASSERT_* macros)
#
# usage: rmc_assertions abort|exit|throw
#
export RMC_ASSERTIONS
rmc_assertions() {
    RMC_ASSERTIONS="$1"
}

rmc_assertions_resolve() {
    case "$RMC_ASSERTIONS" in
	"")
	    RMC_ASSERTIONS=abort
	    ;;
	abort|exit|throw)
	    ;;
	*)
	    echo "$arg0: invalid assert mode: $RMC_ASSERTIONS" >&2
	    exit 1
	    ;;
    esac
}

rmc_assertions_check() {
    rmc_assertions_resolve
}
