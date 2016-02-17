# Sets the operating system name.  This is normally detected automatically.

export RMC_OS_NAME
rmc_os() {
    RMC_OS_NAME="$1"
}

rmc_os_resolve() {
    # Ubuntu-like systems
    if [ "$RMC_OS_NAME" = ""  -a -f /etc/os-release ]; then
	RMC_OS_NAME=$(
	    source /etc/os-release
	    if [ "$PRETTY_NAME" != "" ]; then
		echo "$PRETTY_NAME"
	    elif [ "$NAME" != "" -a "$VERSION_ID" != "" ]; then
		echo "$NAME $VERSION_ID"
	    fi
	)
    fi

    # Debian-like systems (other than Ubuntu-like, above)
    if [ "$RMC_OS_NAME" = "" -a -f /etc/debian_version ]; then
	RMC_OS_NAME="debian-$(cat /etc/debian_version)"
    fi

    # Other systems: use the kernel version just so we have something even though it isn't the OS version
    if [ "$RMC_OS_NAME" = "" ]; then
	    local kernel=$(uname -s)
    fi
}

rmc_os_check() {
    rmc_os_resolve
    if [ "$RMC_OS_NAME" = "" ]; then
	echo "$arg0: unknown operating system name (use rmc_os to set it)" >&2
	exit 1
    fi
}
