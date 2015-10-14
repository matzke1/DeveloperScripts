# Parallelism limit
#
# usage: rmc_parallelism N|system|unlimited
#
# where "N" means limit parallelism to N procs (as in "make -jN")
#       "system" limit to the number of CPU cores present on this machine
#       "unlimited" means no limit (as in "make -j" without a number)
#
export RMC_PARALLELISM
rmc_parallelism() {
    RMC_PARALLELISM="$1"
}

# Resolve parallelism variables
rmc_parallelism_resolve() {
    case "$RMC_PARALLELISM" in
        ""|system)
            local nprocs=$(sed -n '/^processor[ \t]*:/p' /proc/cpuinfo |wc -l)
            [ -n "$nprocs" ] || nprocs=1
            RMC_PARALLELISM="$nprocs"
            ;;
        unlimited|[0-9]*[0-9])
            : fine as is
            ;;
        *)
            echo "$arg0: invalid parallelism: '$RMC_PARALLELISM'" >&2
            ;;
    esac
}

# Check that parallelism is valid
rmc_parallelism_check() {
    rmc_parallelism_resolve
}
