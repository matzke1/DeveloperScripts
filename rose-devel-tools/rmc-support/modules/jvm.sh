# Directory containing libjvm.so
export RMC_JVM_ROOT

rmc_jvm() {
    RMC_JVM_ROOT="$1"
}

rmc_jvm_resolve() {
    if [ "$RMC_JVM_ROOT" = "" ]; then
	# Fixme: This doesn't really work right because there's no requirement that a JDK be installed
	# or that the JDK is installed near the JRE.  This happens to work okay on Debian 8.
        local javac=$(which javac)
	if [ "$javac" = "" ]; then
	    echo "$arg0: no 'javac' in the path" >&2
	    exit 1
	fi
	javac=$(realpath "$javac")
        local bindir="${javac%/*}"
        local libdir=$(realpath "$bindir/../jre")
        local libjvm=$(find "$libdir" -name 'libjvm.so' |head -n1)
        RMC_JVM_ROOT="${libjvm%/*}"
        if [ ! -d "$RMC_JVM_ROOT" ]; then
            echo "$arg0: cannot find libjvm.so" >&2
            exit 1
        fi
    else
        if [ ! -d "$RMC_JVM_ROOT" ]; then
            echo "$arg0: libjvm directory is not valid: $RMC_JVM_ROOT" >&2
            exit 1
        fi
        RMC_JVM_ROOT=$(realpath "$RMC_JVM_ROOT")
    fi
    rmc_add_library_path jvm .
}

rmc_jvm_check() {
    rmc_jvm_resolve
}
