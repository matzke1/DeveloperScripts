# Sets the operating system name.  This is normally detected automatically.

export RMC_OS_NAME
rmc_os() {
    RMC_OS_NAME="$1"
}

rmc_os_resolve() {
    if [ "$RMC_OS_NAME" = "" ]; then
	if [ -f /etc/debian_version ]; then
	    RMC_OS_NAME="debian-$(cat /etc/debian_version)"
        else
	    local kernel=$(uname -s)
	fi
    fi
}

rmc_os_check() {
    rmc_os_resolve
    if [ "$RMC_OS_NAME" = "" ]; then
	echo "$arg0: unknown operating system name (use rmc_os to set it)" >&2
	exit 1
    fi
}
