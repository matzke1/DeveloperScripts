# Sets the operating system name.  This is normally detected automatically.

export RMC_OS_NAME
export RMC_OS_NAME_FILE

rmc_os() {
    RMC_OS_NAME="$1"
}

rmc_os_resolve() {
    # Debian/Ubuntu-like systems
    [ "$RMC_OS_NAME" = "" -a -r /etc/os-release ] && \
	RMC_OS_NAME=$(source /etc/os-release; echo $NAME $VERSION_ID)

    # Other debian-like systems
    [ "$RMC_OS_NAME" = "" -a -r /etc/debian_version ] && \
	RMC_OS_NAME="Debian $(cat /etc/debian_version)"

    # Redhat-like systems
    [ "$RMC_OS_NAME" = "" -a -r /etc/redhat-release ] && \
	RMC_OS_NAME=$(cat /etc/redhat-release)

    # All others, fall back to the Linux kernel version
    [ "$RMC_OS_NAME" = "" ] && \
	RMC_OS_NAME="Unknown $(uname -s)"

    # Create a version that can be easily used as part of file names.
    RMC_OS_NAME_FILE=$(echo -n "$RMC_OS_NAME" |tr -c '[+_.=a-zA-Z0-9-]' '_')
}

rmc_os_check() {
    rmc_os_resolve
    if [ "$RMC_OS_NAME" = "" ]; then
	echo "$arg0: unknown operating system name (use rmc_os to set it)" >&2
	exit 1
    fi

    # Add extra libraries that are pretty much always the same. These should maybe be in the user's environment
    # statically if they're always required and based only on the operating system name.
    case "$RMC_OS_NAME_FILE" in
	Red_Hat_Enterprise_Linux_Workstation_release_6.7__Santiago_)
	    local f
	    for f in											\
		/nfs/casc/overture/ROSE/opt/rhel6/x86_64/gcc/4.8.1/mpc/1.0/mpfr/3.1.2/gmp/5.1.2/lib64	\
		/nfs/casc/overture/ROSE/opt/rhel6/x86_64/gmp/5.1.2/gcc/4.4.7/lib			\
		/nfs/casc/overture/ROSE/opt/rhel6/x86_64/mpc/1.0/gcc/4.4.7/mpfr/3.1.2/gmp/5.1.2/lib	\
		/nfs/casc/overture/ROSE/opt/rhel6/x86_64/mpfr/3.1.2/gcc/4.4.7/gmp/5.1.2/lib
	    do
		RMC_RMC_LIBDIRS=$(rmc_adjust_list prepend_or_move "$f" : "$RMC_RMC_LIBDIRS")
	    done
	    ;;
    esac
}
