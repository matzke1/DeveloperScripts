export LD_LIBRARY_PATH

########################################################################################################################
# Convert relative path to absolute path, and remove extra "." and ".." components.
rmc_realpath_command=
rmc_realpath() {
    if [ "$rmc_realpath_command" = "" ]; then
	if [ "$(which realpath)" = "" ]; then
	    echo "$arg0: \"realpath\" is not installed; please install it" >&2
	    exit 1
	fi
	# Old versions of realpath (~2009) don't support "-m", produce an error message, but exit with success.
	if realpath -m abc 2>&1 |grep 'invalid option' >/dev/null; then
	    rmc_realpath_command=builtin
	else
	    rmc_realpath_command=realpath
	fi
    fi

    if [ "$rmc_realpath_command" = "builtin" ]; then
	if [ "$1" = "-m" ]; then
	    [ "$2" = "" ] && return 0
	    if [ "${2#/}" = "$2" ]; then
		echo "$(pwd)/$2"
	    else
		echo "$2"
	    fi
        else
            realpath "$@"
	fi
    else
	realpath "$@"
    fi
}

########################################################################################################################
# Check whether $1 looks like a version number.
rmc_is_version_string() {
    perl -e 'exit(0 == $ARGV[0] =~ /^\d+(\.\d+)+$/)' "$1"
}

########################################################################################################################
# Compare two version strings. Arguments are VERSION1 OPERATION VERSION2 where OPERATION is "eq", "le", or "ge".
rmc_versions_ordered() {
    local version1="$1" operation="$2" version2="$3"
    local i
    for i in $(seq 1 4); do
        local v1=$(echo "$version1" |cut -d. -f$i)
        local v2=$(echo "$version2" |cut -d. -f$i)
        case "$operation" in
            eq)
                [ "$v1" != "$v2" ] && return 1
                ;;
            le)
                [ "$v1" '<' "$v2" ] && return 0
                [ "$v1" '>' "$v2" ] && return 1
                ;;
            ge)
                [ "$v1" '>' "$v2" ] && return 0
                [ "$v1" '<' "$v2" ] && return 1
                ;;
        esac
    done
    return 0
}

########################################################################################################################
# Sets variables based on arguments. The variables are:
#   RMC_*_VERSION
#   RMC_*_BASEDIR
#   RMC_*_ROOT
rmc_parse_version_or() {
    local or_else="$1" # directory|file|optional
    local pkg="$2"
    local arg1="$3"
    local arg2="$4"
    
    local pkguc=$(echo "$pkg" |tr a-z A-Z)

    if [ "$arg1" = "no" -o "$arg1" = "none" ]; then
	if [ "$arg2" != "" ]; then
	    echo "rmc_$pkg: cannot specify both '$arg1' and a location" >&2
	    exit 1
	fi
        eval 'RMC_'$pkguc'_VERSION=none'
        eval 'RMC_'$pkguc'_BASEDIR='
        eval 'RMC_'$pkguc'_ROOT='
    elif [ "$arg1" = "system" -o "$arg1" = "yes" ]; then
	if [ "$arg2" != "" ]; then
	    echo "rmc_$pkg: cannot specify both '$arg' and a location" >&2
	    exit 1
	fi
        eval 'RMC_'$pkguc'_VERSION=system'
        eval 'RMC_'$pkguc'_BASEDIR='
        eval 'RMC_'$pkguc'_ROOT='
    elif rmc_is_version_string "$arg1"; then
        eval 'RMC_'$pkguc'_VERSION="$arg1"'
        eval 'RMC_'$pkguc'_BASEDIR="$arg2"'
        eval 'RMC_'$pkguc'_ROOT='
    elif [ "$arg2" != "" ]; then
        echo "rmc_$pkg: not a version number: '$arg1'" >&2
        exit 1
    elif [ "$or_else" = "directory" ]; then
	if [ ! -d "$arg1" ]; then
	    echo "rmc_$pkg: not a directory: $arg1" >&2
	    exit 1
	fi
	eval 'RMC_'$pkguc'_VERSION='
	eval 'RMC_'$pkguc'_BASEDIR='
	eval 'RMC_'$pkguc'_ROOT="$arg1"'
    elif [ "$or_else" = "file" ]; then
	if [ ! -r "$arg1" ]; then
	    echo "rmc_$pkg: not a file: $arg1" >&2
	    exit 1
	fi
	eval 'RMC_'$pkguc'_VERSION='
	eval 'RMC_'$pkguc'_BASEDIR='
	eval 'RMC_'$pkguc'_ROOT="$arg1"'
    else
        eval 'RMC_'$pkguc'_VERSION='
        eval 'RMC_'$pkguc'_BASEDIR='
        eval 'RMC_'$pkguc'_ROOT="$arg1"'
    fi
}


########################################################################################################################
# Resolve ROOT and VERSION  parameters for a package.
rmc_resolve_root_and_version() {
    local pkg="$1"
    local pkguc=$(echo "$pkg" |tr a-z A-Z)
    local pkglc=$(echo "$pkg" |tr A-Z a-z)
    local base="$RMC_RMC_DEPENDENCIES/$pkglc"
    local root=$(eval echo '$RMC_'$pkguc'_ROOT')
    local file=$(eval echo '$RMC_'$pkguc'_FILE')
    local vers=$(eval echo '$RMC_'$pkguc'_VERSION')

    # ROOT is usually a directory, but could be a file at this point. We want ROOT to always be the installation
    # directory, so if ROOT is currently a file we should store it in FILE and reset ROOT to the directory
    # containing that file.  Use "! -d _ -a -r _" instead of "-f" to check for files becuase the're often symbolic
    # links, for which "-f _" is false.
    if [ ! -d "$root" -a -r "$root" ]; then
	if [ "$file" != "" -a "$file" != "$root" ]; then
	    echo "$arg0: $pkg has conflicting ROOT and FILE properties (root=\"$root\", file=\"$file\")" >&2
	    exit 1
	fi
	file="$root"
	root="${root%/*}"
    fi

    # User must have specified either a directory (or file) or a version number (or special version word like "none")
    if [ "$root" = "" -a "$vers" = "" ]; then
	echo "$arg0: $pkg root or version number required" >&2
	exit 1
    fi

    if [ "$vers" = "no" -o "$vers" = "none" ]; then
	vers=
	root=
	base=
	file=
    elif [ "$vers" = "system" ]; then
	root=
	base=
	file=
    else	
	# Find the installation root (it need not exsit at this point)
	if [ "$root" = "" ]; then
	    root=$(eval 'rmc_'$pkglc'_root' "$base" "$vers")
	    if [ "$root" = "" ]; then
		echo "$arg0: $pkg cannot be specified by a version number" >&2
		exit 1
	    fi
	fi

	# Find optional canonical file if none specified
	if [ "$file" = "" ]; then
	    file=$(eval 'rmc_'$pkglc'_file' "$root" 2>/dev/null)
	fi

	# Find a version number (the root must exist if no version is specified)
	if [ "$vers" = "" ]; then
	    if [ ! -e "$root" ]; then
		echo "$arg0: $pkg must be installed or a version specified (install in $root)" >&2
		exit 1
	    fi
	    vers=$(eval 'rmc_'$pkglc'_version' "$root")
	    if [ "$vers" = "" -a "$file" != "" ]; then
		vers=$(eval 'rmc_'$pkglc'_version' "$file")
	    fi
	    if [ "$vers" = "" ]; then
		echo "$arg0: cannot determine $pkg version number installed in $root" >&2
		exit 1
	    fi
	fi
    fi

    eval 'RMC_'$pkguc'_BASEDIR="$base"'
    eval 'RMC_'$pkguc'_ROOT="$root"'
    eval 'RMC_'$pkguc'_VERSION="$vers"'
    if [ "$file" != "" ]; then
	eval 'RMC_'$pkguc'_FILE="$file"'
    fi
}

########################################################################################################################
# Check that a package exists and has ROOT and VERSION properties
rmc_check_root_and_version() {
    local pkg="$1"
    local pkguc=$(echo "$pkg" |tr a-z A-Z)
    local pkglc=$(echo "$pkg" |tr A-Z a-z)
    local root=$(eval echo '$RMC_'$pkguc'_ROOT')
    local file=$(eval echo '$RMC_'$pkguc'_FILE')
    local vers=$(eval echo '$RMC_'$pkguc'_VERSION')
    local base=$(eval echo '$RMC_'$pkguc'_BASEDIR')

    # Get the FILE property for a system-installed package
    if [ "$vers" = "system" -a "$root" = "" -a "$file" = "" ]; then
	file=$(eval 'rmc_'$pkg'_find_in_system')
	if [ "$file" = "" ]; then
	    echo "$arg0: $pkg system version cannot be found" >&2
	    exit 1
	fi
    fi

    # Get the ROOT property if possible
    if [ "$root" = "" -a "$file" != "" ]; then
	if [ -d "$file" ]; then
	    root="$file"
	else
	    root=$(rmc_realpath "$file")
	    root="${root%/*}"
	fi
    fi

    # Get the FILE property if possible
    if [ "$file" = "" -a "$root" != "" ]; then
	file=$(eval 'rmc_'$pkglc'_file' "$root")
    fi

    # Check for existence, but only if the user wants it (i.e., version was not "none", but is "system" or something specific)
    if [ "$vers" != "" ]; then
	if [ "$root" = "" -a "$file" = "" ]; then
	    echo "$arg0: $pkg is required" >&2
	    exit 1
	elif [ ! -e "$root" -a ! -e "$file" ]; then
	    echo "$arg0: $pkg installation is missing: $root" >&2
	    exit 1
	elif [ "$vers" = "" ]; then
	    echo "$arg0: $pkg version number is unknown" >&2
	    exit 1
	fi
    fi

    eval 'RMC_'$pkguc'_ROOT="$root"'
    eval 'RMC_'$pkguc'_FILE="$file"'
    eval 'RMC_'$pkguc'_VERSION="$vers"'
    eval 'RMC_'$pkguc'_BASEDIR="$base"'
}

########################################################################################################################
# Read and process the configuration file, $CONFIG_BASE_NAME at the top of the build tree.
rmc_load_configuration() {
    rmc_rosebld_check
    local config="$RMC_ROSEBLD_ROOT/$CONFIG_BASE_NAME"
    if [ ! -r "$config" ]; then
        echo "$arg0: build directory is not initialized" >&2
        exit 1
    fi
    source "$config" || exit 1
    resolve
}

########################################################################################################################
# Find the root directory (or file if $subname isn't empty) for a package.
rmc_find_root() {
    local pkg"=$1" name="$2" subname="$3"
    [ "$name" = "" ] && name=$(echo "$pkg" |tr A-Z a-z)
    local root=$(eval echo '$RMC_'$pkg'_ROOT')
    case "$root" in
        system)
            echo "$name"
            ;;
        ""|no)
            ;;
        *)
            if [ "$subname" = "" ]; then
                echo "$root"
            elif [ -e "$root/$subname" ]; then
                echo "$root/$subname"
            elif [ -e "$root" -a ! -d "$root" ]; then
                echo "$root"
            else
                echo "$arg0: no file found for $name: $root/$subname" >&2
                echo "NOT_FOUND"
            fi
            ;;
    esac
}

########################################################################################################################
# Add a package's library directory to the LD_LIBRARY_PATH if necessary, even if the path doesn't exist.
rmc_add_library_path() {
    local pkg="$1" path="$2"
    local pkguc=$(echo "$pkg" |tr a-z A-Z)
    local root=$(eval echo '$RMC_'$pkguc'_ROOT')
    [ "$root" = "system" -o "$root" = "" ] && return 0
    local full=$(rmc_realpath -m "$root/$path")

    for f in /lib /usr/lib /usr/local/lib; do
        if [ "$full" = "$(rmc_realpath -m "$f")" ]; then
            return 0
        fi
    done
    eval $(path-adjust --var=LD_LIBRARY_PATH --prepend --move insert "$full")
}

########################################################################################################################
# Optionally execute a command.
rmc_execute() {
    local dry_run
    while [ "$#" -gt 0 ]; do
        case "$1" in
            --dry-run)
                dry_run=yes
                shift
                ;;
            *)
                break
                ;;
        esac
    done
    if [ "$dry_run" = "yes" ]; then
        echo "+" "$@" >&2
    else
        eval "$@"
    fi
}

########################################################################################################################
# List installed versions of some dependency.
rmc_list() {
    local pkg="$1" format="$2"
    local pkglc=$(echo "$pkg" |tr A-Z a-z)
    local base="$RMC_RMC_DEPENDENCIES/$pkglc"
    [ -d "$base" ] || return 0
    case "$format" in
	shell)
	    # RMC environment variable settings like "RMC_BOOST_VERSION='1.50' RMC_CXX_NAME='gcc-4.4.5-default'
	    eval 'rmc_'$pkg'_list' "$base"
	    ;;
	human)
	    # Same as "shell" format but show only the variable values (not names, equal signs, or quotes) and use TAB
	    # to separate values from one another.
	    eval 'rmc_'$pkg'_list' "$base" |\
		sed "s/RMC_[A-Za-z_0-9]\+='\([^']*\)'/\1/g" |\
		tr ' ' '\t'
	    ;;
	*)
	    echo "rmc_list: invalid format: $format" >&2
	    exit 1
    esac
}

########################################################################################################################
# The following functions are to resolve interdependencies in the user's configuration settings and to adjust variables
# to their final values.  This is also where we check that the certain desired packages are actually available. The check
# is performed when it is easy to do, otherwise we leave most of the checking up to the configure/cmake steps (that's
# their strong point and we don't want to duplicate that work.

resolve() {
    rmc_os_check
    rmc_rosesrc_check
    rmc_rosebld_check
    rmc_build_check
    [ "$RMC_BUILD_SYSTEM" = "cmake" ] && rmc_cmake_check
    rmc_install_resolve
    rmc_parallelism_check
    rmc_build_check
    rmc_compiler_check
    rmc_debug_resolve
    rmc_warnings_resolve
    rmc_assertions_resolve
    rmc_optim_resolve
    rmc_languages_resolve
    rmc_boost_check
    rmc_edg_check
    rmc_wt_check
    rmc_magic_check
    rmc_yaml_check
    rmc_dlib_check
    rmc_yices_check
    rmc_python_check
    rmc_jvm_check
    rmc_readline_check
    rmc_sqlite_check
    rmc_qt_check
    rmc_doxygen_check
    resolve_so_paths
}

resolve_so_paths() {
    # These are necessary if you want to run an executable directly without going through the GNU libtool shell scripts. It's
    # sometimes necessary if you want to use GDB on a program that hasn't been installed yet (on the other hand, older versions
    # of nemiver seem to be able to debug through the libtool script).
    for f in src/.libs \
             libltdl/.libs \
             src/3rdPartyLibraries/libharu-2.1.0/src/.libs \
             src/3rdPartyLibraries/qrose/QRoseLib/.libs; do
        eval $(path-adjust --var=LD_LIBRARY_PATH --prepend --move insert "$RMC_ROSEBLD_ROOT/$f")
    done
}
