# EDG version to compile into ROSE.
#
# usage: rmc_edg VERSION
#
export RMC_EDG_VERSION
rmc_edg() {
    RMC_EDG_VERSION="$1"
}

# Resolve package variables
rmc_edg_resolve() {
    if [ "$RMC_EDG_VERSION" = "" ]; then
        RMC_EDG_VERSION="4.7"
    fi
}

# Check that package is installed
rmc_edg_check() {
    rmc_edg_resolve
}
