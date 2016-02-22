# Sets the operating system name.  This is normally detected automatically.

export RMC_OS_NAME
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
}

rmc_os_check() {
    rmc_os_resolve
    if [ "$RMC_OS_NAME" = "" ]; then
	echo "$arg0: unknown operating system name (use rmc_os to set it)" >&2
	exit 1
    fi
}
