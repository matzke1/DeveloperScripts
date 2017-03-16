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

# Name of the fortran compiler that we actually use, which might be different than RMC_FORTRAN_*.  At this time, ROSE
# does not support the Intel Fortran compiler (ifort), so if the Intel C/C++ compilers are used, then do not specify
# a Fortran compiler -- ROSE will automatically use whatever "gfortran" is in $PATH (if any).  Similarly, if LLVM C/C++
# compilers are used, use the "gfortran" in $PATH since LLVM doesn't have a Fortran compiler.
rmc_rose_fortran_compiler() {
    case "$RMC_CXX_VENDOR" in
	gcc) echo "$RMC_FORTRAN_NAME" ;;
	llvm|intel) : ambivalent ;;
	*) echo "$arg0: unknown compiler vendor: $RMC_CXX_VENDOR" >&2; exit 1 ;;
    esac
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

    # Precompiled headers only work with GCC and LLVM
    local with_pch=
    [ "$RMC_CXX_VENDOR" = "gcc" -o "$RMC_CXX_VENDOR" = "llvm" ] && with_pch="--with-pch"
    # As of June 2016, GCC's precompiled headers introduce an off-by-one error in error messages and DWARF line numbers
    with_pch="--without-pch"

    # Run the configure command
    (
        set -e
        cd "$RMC_ROSEBLD_ROOT"
        rmc_execute $dry_run \
 	    CC="$RMC_CC_NAME" \
	    CXX="$RMC_CXX_NAME" \
	    CXXFLAGS="'$RMC_CXX_SWITCHES'" \
	    FC="$(rmc_rose_fortran_compiler)" \
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
	    $(rmc_autoconf_with dwarf) \
	    $(rmc_autoconf_with_or_nothing gfortran "$(rmc_rose_fortran_compiler)") \
            --with-java="$RMC_JAVA_FILE" \
            $(rmc_autoconf_with readline libreadline) \
            $(rmc_autoconf_with magic) \
            $with_pch \
            $(rmc_autoconf_with python python "$RMC_PYTHON_FILE") \
            $qt_flags \
            $(rmc_autoconf_with sqlite sqlite3) \
            $(rmc_autoconf_with wt) \
            $(rmc_autoconf_with yaml) \
            $(rmc_autoconf_with yices)
    )
}
