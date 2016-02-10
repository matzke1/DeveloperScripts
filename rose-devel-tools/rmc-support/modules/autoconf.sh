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

# Run the "configure" command
rmc_autoconf_run() {
    local dry_run="$1"

    # Fixme: This really depends on the compiler
    local cxx_debug c_debug
    if [ "$RMC_DEBUG" = "yes" ]; then
	cxx_debug="-g"
	c_debug="-g"
    fi

    # Fixme: This really depends on the compiler
    local cxx_optim c_optim
    if [ "$RMC_OPTIM" = "yes" ]; then
        cxx_optim="'-O3 -fomit-frame-pointer -DNDEBUG'"
	c_optim="'-O3 -fomit-frame-pointer -DNDEBUG'"
    else
        cxx_optim="-O0"
	c_optim="-O0"
    fi

    local cxx_warn c_warn
    if [ "$RMC_WARNINGS" = "yes" ]; then
	if [ "$RMC_CXX_VENDOR" = "gcc" ]; then
	    cxx_warn="-Wall"
	    # Turn off some warnings from 3rd-party headers (mostly boost)
	    if rmc_versions_ordered "$RMC_CXX_VERSION" ge "4.8.0"; then
		cxx_warn="$cxx_warn -Wno-unused-local-typedefs -Wno-attributes"
	    fi
	    cxx_warn="'$cxx_warn'"
	    c_warn="-Wall"
	fi
    fi

    # Qt detections is somewhat broken in ROSE's config system. For one thing, it doesn't
    # understand "--without-qt"
    local qt_flags=$(rmc_autoconf_with qt)
    if [ "$qt_flags" = "--without-qt" ]; then
	qt_flags=
    else
	qt_flags="$qt_flags --with-qt-lib --with-roseQt"
    fi

    # C compiler based on C++ compiler
    local cc_name=
    case "$RMC_CXX_NAME" in
	g++*)
	    cc_name=gcc${RMC_CXX_NAME#g++}
	    ;;
	*)
	    cc_name=$(echo "$RMC_CXX_NAME" |perl -pe 's/\+\+//g')
	    ;;
    esac

    # Run the configure command
    (
        set -e
        cd "$RMC_ROSEBLD_ROOT"
        rmc_execute $dry_run \
 	    CC="$cc_name" CXX="$RMC_CXX_NAME" CXXFLAGS="$RMC_CXX_SWITCHES" \
            $RMC_ROSESRC_ROOT/configure \
            --disable-boost-version-check \
	    --disable-gcc-version-check \
            --enable-assertion-behavior=$RMC_ASSERTIONS \
            --enable-edg_version="$RMC_EDG_VERSION" \
            --enable-languages="$RMC_LANGUAGES" \
            --prefix="$RMC_INSTALL_ROOT" \
            --with-CFLAGS=-fPIC \
            --with-CXXFLAGS=-fPIC \
            --with-CXX_DEBUG="$cxx_debug" \
            --with-CXX_OPTIMIZE="$cxx_optim" \
            --with-CXX_WARNINGS="$cxx_warn" \
            --with-C_DEBUG="$c_debug" \
            --with-C_OPTIMIZE="$c_optim" \
            --with-C_WARNINGS="$c_warn" \
            --with-ROSE_LONG_MAKE_CHECK_RULE=yes \
            --with-boost="$RMC_BOOST_ROOT" \
            $(rmc_autoconf_with dlib) \
            $(rmc_autoconf_with doxygen doxygen "$RMC_DOXYGEN_FILE") \
            --with-java=/usr/lib/jvm/java-7-sun \
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
