# Program coverage analysis.
#
# usage: rmc_code_coverage yes|no
#
# When set to "yes", appropriate compiler switches are added to the compiler.
export RMC_CODE_COVERAGE

rmc_code_coverage() {
    RMC_CODE_COVERAGE="$1"
}

rmc_code_coverage_resolve() {
    case "$RMC_CODE_COVERAGE" in
	"")
	    RMC_CODE_COVERAGE=no
	    ;;
	yes|no)
	    : all okay
	    ;;
	*)
	    echo "usage: rmc_code_coverage yes|no" >&2
	    exit 1
    esac
}

rmc_code_coverage_check() {
    rmc_code_coverage_resolve
}
