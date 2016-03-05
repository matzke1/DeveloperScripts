# Java development kit installation directory
#
# usage: rmc_java VERSION
#        rmc_java DIRECTORY
#
export RMC_JAVA_BASEDIR
export RMC_JAVA_VERSION
export RMC_JAVA_ROOT
export RMC_JAVA_FILE

rmc_java() {
    rmc_parse_version_or directory java "$@"
}

# Return version number for existing installation
rmc_java_version() {
    local root="$1"
    local javac="$root/bin/javac -version";
    local output=$("$javac" -version 2>&1 |head -n1)
    perl -e '$ARGV[0] =~ /(\d([._]\d+)+)/ && print $1' "$output"
}

# Obtain an installation directory name from a version. Directory need not exist.
rmc_java_root() {
    local base="$1" vers="$2"
    echo "$base/$vers/$RMC_OS_NAME_FILE"
}

# Find canonical installed file for package. We'll use "bin/javac" since every JDK should have it.
rmc_java_file() {
    local root="$1"
    local file="$root/bin/javac"
    [ -x "$file" ] && echo "$file"
}

# Find executable for "system" version
rmc_java_find_in_system() {
    for dir in java-7-sun jdk1.7.0_51 default-java java-7-openjdk-amd64 java-openjdk; do
	if [ -x "/usr/lib/jvm/$dir/bin/javac" ]; then
	    echo "/usr/lib/jvm/$dir/bin/javac:/usr/lib/jvm/$dir"
	    return 0
	fi
    done
}

# Resolve package variables
rmc_java_resolve() {
    rmc_os_check
    rmc_resolve_root_and_version java
}

# Check that package is installed
rmc_java_check() {
    rmc_java_resolve
    rmc_check_root_and_version java

    # We need the directory for libjvm.so, which is in a sort of strange place instead of "lib"
    rmc_add_library_path java jre/lib/amd64/server
}
