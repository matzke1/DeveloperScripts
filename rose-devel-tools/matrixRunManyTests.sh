#!/bin/bash

expect_yes() {
    local prompt="$1"
    read -p "$prompt [Y/n] "
    case "$REPLY" in
        y|yes|Y|YES|Yes|"")
            return 0
            ;;
    esac
    return 1
}

die() {
    echo "$@" >&2
    exit 1
}

echo "This script configures and runs the ROSE configuration matrix testing. You can run this script concurrently"
echo "in as many terminal windows as you like and they can all share the same directories.  Each of the questions"
echo "below have a corresponding environment variable which you can set prior to invoking this script. In fact,"
echo "you don't really need this script at all if you'd rather just invoke 'matrixRunOneTest.sh' directly. Both"
echo "scripts provide default values for all variables (although they might not be the same defaults)."

echo
: ${MATRIX_ROOT:="$HOME/matrix-testing"}
read -p "Directory to hold all matrix testing files (MATRIX_ROOT): " -i "$MATRIX_ROOT" -e MATRIX_ROOT
mkdir -p "$MATRIX_ROOT" || exit 1
export MATRIX_ROOT

echo
: ${WORKSPACE:="$MATRIX_ROOT/tmp"}
read -p "Temporary matrix testing workspace (WORKSPACE): " -i "$WORKSPACE" -e WORKSPACE
mkdir -p "$WORKSPACE" || exit 1
export WORKSPACE

echo
: ${ROSE_SRC:="$HOME/GS-CAD/ROSE/matrix/source-repo"}
read -p "Location of quiescent ROSE source tree (ROSE_SRC): " -i "$ROSE_SRC" -e ROSE_SRC
[ -e "$ROSE_SRC" ] || die "ROSE source tree must exist: $ROSE_SRC"
export ROSE_SRC

# We can't run "build" from this script because we've promised not to modify the ROSE build tree. There might be
# other scripts already running matrix tests and us running "build" would screw them up!
expect_yes "Is the ROSE source repo up-to-date?" || exit 1
expect_yes "Do you promise not to edit/change the repo while tests are running?" || exit 1
expect_yes "Have you run 'build' in the repo already?" || exit 1

echo
: ${ROSE_TOOLS:="$HOME/GS-CAD/ROSE/matrix/tools-build"}
read -p "Location of build tree for ROSE matrix tools (ROSE_TOOLS): " -i "$ROSE_TOOLS" -e ROSE_TOOLS
if [ ! -e "$ROSE_TOOLS/projects/MatrixTesting/matrixTestResult" ]; then
    echo "You must build the ROSE library and the projects/MatrixTesting directories before you can start"
    echo "any matrix tests.  You should do this with RMC so that this script can find the correct dynamic"
    echo "libraries, but you don't need to 'make install' anything."
    exit 1
fi
[ $(rmc -C "$ROSE_TOOLS" bash -c 'echo $RG_SRC') != "" ] || die "must be configured with RMC: $ROSE_TOOLS"
export ROSE_TOOLS="$ROSE_TOOLS/projects/MatrixTesting"

echo
echo "The matrix testing selects configurations at random by querying the database. Since the database doesn't"
echo "know what's installed on our system, many of the configurations returned from the database will be invalid"
echo "here and will be kicked out without even testing.  If our valid configuration space is a tiny fraction of"
echo "the configuration space known by the database, then we'll spend most of our time requesting and kicking out"
echo "configurations. Therefore, the following overrides can be used to ignore certain things from the database"
echo "and choose them ourself. Their values are the same as what's accepted by the corresponding 'rmc_*' directive"
echo "in RMC configuration files. For example, the database knows about many compilers but we maybe have only one"
echo "installed here, so we would set the compiler override to the string 'gcc-4.8-default gcc-4.8-c++11', which"
echo "means no matter what compiler the database tells us to use, use one of these two. (RMC specifies compilers"
echo "as a triplet: VENDOR-VERSION-LANGUAGE)."

while true; do
    read -p "  Override build system       (OVERRIDE_BUILD)        : " -i "$OVERRIDE_BUILD" -e OVERRIDE_BUILD
    read -p "  Override frontend languages (OVERRIDE_LANGUAGES)    : " -i "$OVERRIDE_LANGUAGES" -e OVERRIDE_LANGUAGES
    read -p "  Override compiler           (OVERRIDE_COMPILER)     : " -i "$OVERRIDE_COMPILER" -e OVERRIDE_COMPILER
    read -p "  Override debug mode         (OVERRIDE_DEBUG)        : " -i "$OVERRIDE_DEBUG" -e OVERRIDE_DEBUG
    read -p "  Override optimize mode      (OVERRIDE_OPTIMIZE)     : " -i "$OVERRIDE_OPTIMIZE" -e OVERRIDE_OPTIMIZE
    read -p "  Override warnings mode      (OVERRIDE_WARNINGS)     : " -i "$OVERRIDE_WARNINGS" -e OVERRIDE_WARNINGS
    read -p "  Override code_coverage      (OVERRIDE_CODE_COVERAGE): " -i "$OVERRIDE_CODE_COVERAGE" -e OVERRIDE_CODE_COVERAGE
    read -p "  Override assertions mode    (OVERRIDE_ASSERTIONS)   : " -i "$OVERRIDE_ASSERTIONS" -e OVERRIDE_ASSERTIONS
    read -p "  Override boost versions     (OVERRIDE_BOOST)        : " -i "$OVERRIDE_BOOST" -e OVERRIDE_BOOST
    read -p "  Override cmake versions     (OVERRIDE_CMAKE)        : " -i "$OVERRIDE_CMAKE" -e OVERRIDE_CMAKE
    read -p "  Override dlib versions      (OVERRIDE_DLIB)         : " -i "$OVERRIDE_DLIB" -e OVERRIDE_DLIB
    read -p "  Override doxygen versions   (OVERRIDE_DOXYGEN)      : " -i "$OVERRIDE_DOXYGEN" -e OVERRIDE_DOXYGEN
    read -p "  Override edg versions       (OVERRIDE_EDG)          : " -i "$OVERRIDE_EDG" -e OVERRIDE_EDG
    read -p "  Override magic versions     (OVERRIDE_MAGIC)        : " -i "$OVERRIDE_MAGIC" -e OVERRIDE_MAGIC
    read -p "  Override python versions    (OVERRIDE_PYTHON)       : " -i "$OVERRIDE_PYTHON" -e OVERRIDE_PYTHON
    read -p "  Override qt versions        (OVERRIDE_QT)           : " -i "$OVERRIDE_QT" -e OVERRIDE_QT
    read -p "  Override readline versions  (OVERRIDE_READLINE)     : " -i "$OVERRIDE_READLINE" -e OVERRIDE_READLINE
    read -p "  Override sqlite versions    (OVERRIDE_SQLITE)       : " -i "$OVERRIDE_SQLITE" -e OVERRIDE_SQLITE
    read -p "  Override wt versions        (OVERRIDE_WT)           : " -i "$OVERRIDE_WT" -e OVERRIDE_WT
    read -p "  Override yaml versions      (OVERRIDE_YAML)         : " -i "$OVERRIDE_YAML" -e OVERRIDE_YAML
    read -p "  Override yices versions     (OVERRIDE_YICES)        : " -i "$OVERRIDE_YICES" -e OVERRIDE_YICES
    echo
    expect_yes "Are you satisfied with these overrides?" && break
done

export OVERRIDE_BUILD OVERRIDE_LANGUAGES OVERRIDE_COMPILER OVERRIDE_DEBUG
export OVERRIDE_OPTIMIZE OVERRIDE_WARNINGS OVERRIDE_CODE_COVERAGE
export OVERRIDE_ASSERTIONS OVERRIDE_BOOST OVERRIDE_CMAKE OVERRIDE_DLIB
export OVERRIDE_DOXYGEN OVERRIDE_EDG OVERRIDE_MAGIC OVERRIDE_PYTHON
export OVERRIDE_QT OVERRIDE_READLINE OVERRIDE_SQLITE OVERRIDE_WT
export OVERRIDE_YAML OVERRIDE_YICES

echo
echo "Type 'stop' and Enter at any time to stop testing at the next break."
echo "Or type C-c a couple times to interrupt in the middle of a test."
echo
expect_yes "Shall I start running tests? " || exit 0

testNumber=0
while true; do
    testNumber=$[testNumber+1]
    (figlet "Test $testNumber" || banner "Test $testNumber" || (echo; echo "Test $testNumber"; echo)) 2>/dev/null
    matrixRunOneTest.sh
    read -t 1			# use 1 second so Ctrl-C works over a slow link if a bug causes us to spew
    [ "$REPLY" = "stop" ] && break
done
