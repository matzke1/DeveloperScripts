# No user configurable stuff yet

rmc_autoconf_resolve() {
    : nothing to do
}

rmc_autoconf_check() {
    : nothing to do
}

# Generate an optional autotools "--with-..." argument for a package.
rmc_autoconf_with() {
    local pkg="$1" switch_name="$2" value="$3"
    [ "$switch_name" = "" ] && switch_name="$pkg"
    local pkguc=$(echo "$pkg" |tr a-z A-Z)
    local root=$(eval echo '$RMC_'$pkguc'_ROOT')
    local vers=$(eval echo '$RMC_'$pkguc'_VERSION')

    if [ "$vers" = "system" ]; then
        echo "--with-$switch_name"
    elif [ "$vers" = "no" -o "$vers" = "none" ]; then
        echo "--without-$switch_name"
    elif [ "$vers" = "ambivalent" ]; then
	: nothing
    elif [ "$value" != "" ]; then
	echo "--with-$switch_name='$value'";
    elif [ "$root" != "" ]; then
        echo "--with-$switch_name='$root'";
    else
	echo "--without-$switch_name"
    fi
}

# Return a string or nothing
rmc_autoconf_with_or_nothing() {
    local switch_name="$1"
    local value="$2"
    if [ "$value" != "" ]; then
	echo "--with-$switch_name='$value'"
    fi
}

# Run the "configure" command
rmc_autoconf_run() {
    local dry_run="$1"

    # Qt detections is somewhat broken in ROSE's config system. For one thing, it doesn't
    # understand "--without-qt"
    local qt_flags=$(rmc_autoconf_with qt)
    if [ "$qt_flags" = "--without-qt" ]; then
	qt_flags=
    else
	qt_flags="$qt_flags --with-qt-lib --with-roseQt"
    fi

    # C compiler based on C++ compiler
    local cxx_basename=${RMC_CXX_NAME##*/}
    local cxx_not_base=${RMC_CXX_NAME%/*}
    [ "$cxx_not_base" = "$RMC_CXX_NAME" ] && cxx_not_base=""
    [ "$cxx_not_base" = "" ] || cxx_not_base="$cxx_not_base/"

    local cc_basename=
    case "$cxx_basename" in
        g++*)   
            cc_basename=gcc${cxx_basename#g++}
            ;;      
        *)      
            cc_basename=$(echo "$cxx_basename" |perl -pe 's/\+\+//g')
            ;;      
    esac    
    local cc_name="$cxx_not_base$cc_basename"

    # Run the configure command
    (
        set -e
        cd "$RMC_ROSEBLD_ROOT"
        rmc_execute $dry_run \
 	    CC="$cc_name" CXX="$RMC_CXX_NAME" CXXFLAGS="'$RMC_CXX_SWITCHES'" \
            $RMC_ROSESRC_ROOT/configure \
            --disable-boost-version-check \
	    --disable-gcc-version-check \
            --enable-assertion-behavior=$RMC_ASSERTIONS \
            --enable-edg_version="$RMC_EDG_VERSION" \
            --enable-languages="$RMC_LANGUAGES" \
            --prefix="$RMC_INSTALL_ROOT" \
            --with-CFLAGS=-fPIC \
            --with-CXXFLAGS=-fPIC \
	    $(rmc_autoconf_with_or_nothing CXX_DEBUG "$RMC_CXX_SWITCHES_DEBUG") \
	    $(rmc_autoconf_with_or_nothing CXX_OPTIMIZE "$RMC_CXX_SWITCHES_OPTIM") \
	    $(rmc_autoconf_with_or_nothing CXX_WARNINGS "$RMC_CXX_SWITCHES_WARN") \
	    $(rmc_autoconf_with_or_nothing C_DEBUG "$RMC_CXX_SWITCHES_DEBUG") \
	    $(rmc_autoconf_with_or_nothing C_OPTIMIZE "$RMC_CXX_SWITCHES_OPTIM") \
            $(rmc_autoconf_with_or_nothing C_WARNINGS "$RMC_CXX_SWITCHES_WARN") \
            --with-ROSE_LONG_MAKE_CHECK_RULE=yes \
            --with-boost="$RMC_BOOST_ROOT" \
            $(rmc_autoconf_with dlib) \
            $(rmc_autoconf_with doxygen doxygen "$RMC_DOXYGEN_FILE") \
	    $(rmc_autoconf_with fortran gfortran "$RMC_FORTRAN_NAME") \
            --with-java="$RMC_JAVA_FILE" \
            $(rmc_autoconf_with readline libreadline) \
            $(rmc_autoconf_with magic) \
            --with-pch \
            $(rmc_autoconf_with python python "$RMC_PYTHON_FILE") \
            $qt_flags \
            $(rmc_autoconf_with sqlite sqlite3) \
            $(rmc_autoconf_with wt) \
            $(rmc_autoconf_with yaml) \
            $(rmc_autoconf_with yices)
    )
}
