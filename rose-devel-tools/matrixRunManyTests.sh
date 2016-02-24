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

: ${MATRIX_ROOT:="$HOME/matrix-testing"}
read -p "Directory to hold all matrix testing files: " -i "$MATRIX_ROOT" -e MATRIX_ROOT
mkdir -p "$MATRIX_ROOT" || exit 1
export MATRIX_ROOT

echo
: ${WORKSPACE:="$MATRIX_ROOT/tmp"}
read -p "Location of temporary matrix testing workspace (need not exist): " -i "$WORKSPACE" -e WORKSPACE
mkdir -p "$WORKSPACE" || exit 1
export WORKSPACE

echo
: ${ROSE_SRC:="$HOME/GS-CAD/ROSE/matrix/source-repo"}
read -p "Location of quiscient ROSE source tree (must exist): " -i "$ROSE_SRC" -e ROSE_SRC
[ -e "$ROSE_SRC" ] || die "ROSE source tree must exist: $ROSE_SRC"
export ROSE_SRC

# We can't run "build" from this script because we've promised not to modify the ROSE build tree. There might be
# other scripts already running matrix tests and us running "build" would screw them up!
expect_yes "Is the ROSE source repo up-to-date?" || exit 1
expect_yes "Do you promise not to edit/change the repo while tests are running?" || exit 1
expect_yes "Have you run 'build' in the repo already?" || exit 1

echo
: ${ROSE_TOOLS:="$HOME/GS-CAD/ROSE/matrix/tools-build"}
read -p "Location of build tree for ROSE matrix tools (built with RMC): " -i "$ROSE_TOOLS" -e ROSE_TOOLS
[ -e "$ROSE_TOOLS/projects/MatrixTesting/matrixTestResult" ] || die "tools must be built already: $ROSE_TOOLS"
[ $(rmc -C "$ROSE_TOOLS" bash -c 'echo $RG_SRC') != "" ] || die "must be configured with RMC: $ROSE_TOOLS"
export ROSE_TOOLS="$ROSE_TOOLS/projects/MatrixTesting"

echo
echo "The following settings are to override values used for random testing. You don't need to set"
echo "any of these if you don't want since those values that come from the central server that don't"
echo "make sense here will be kicked out, but if the server's configuration space is much larger than"
echo "our own available configuration space, then we'll spend most of our time kicking out configurations"
echo "that don't make sense here.  Each value is a space-separated list of possibilities. See RMC"
echo "for the values to use, but they're usually just version numbers."
echo

read -p "Override build system      : " -i "$OVERRIDE_BUILD" -e OVERRIDE_BUILD
read -p "Override frontend languages: " -i "$OVERRIDE_LANGUAGES" -e OVERRIDE_LANGUAGES
read -p "Override compiler          : " -i "$OVERRIDE_COMPILER" -e OVERRIDE_COMPILER
read -p "Override debug mode        : " -i "$OVERRIDE_DEBUG" -e OVERRIDE_DEBUG
read -p "Override optimize mode     : " -i "$OVERRIDE_OPTIMIZE" -e OVERRIDE_OPTIMIZE
read -p "Override warnings mode     : " -i "$OVERRIDE_WARNINGS" -e OVERRIDE_WARNINGS
read -p "Override code_coverage     : " -i "$OVERRIDE_CODE_COVERAGE" -e OVERRIDE_CODE_COVERAGE
read -p "Override assertions mode   : " -i "$OVERRIDE_ASSERTIONS" -e OVERRIDE_ASSERTIONS
read -p "Override boost versions    : " -i "$OVERRIDE_BOOST" -e OVERRIDE_BOOST
read -p "Override cmake versions    : " -i "$OVERRIDE_CMAKE" -e OVERRIDE_CMAKE
read -p "Override dlib versions     : " -i "$OVERRIDE_DLIB" -e OVERRIDE_DLIB
read -p "Override doxygen versions  : " -i "$OVERRIDE_DOXYGEN" -e OVERRIDE_DOXYGEN
read -p "Override edg versions      : " -i "$OVERRIDE_EDG" -e OVERRIDE_EDG
read -p "Override magic versions    : " -i "$OVERRIDE_MAGIC" -e OVERRIDE_MAGIC
read -p "Override python versions   : " -i "$OVERRIDE_PYTHON" -e OVERRIDE_PYTHON
read -p "Override qt versions       : " -i "$OVERRIDE_QT" -e OVERRIDE_QT
read -p "Override readline versions : " -i "$OVERRIDE_READLINE" -e OVERRIDE_READLINE
read -p "Override sqlite versions   : " -i "$OVERRIDE_SQLITE" -e OVERRIDE_SQLITE
read -p "Override wt versions       : " -i "$OVERRIDE_WT" -e OVERRIDE_WT
read -p "Override yaml versions     : " -i "$OVERRIDE_YAML" -e OVERRIDE_YAML
read -p "Override yices versions    : " -i "$OVERRIDE_YICES" -e OVERRIDE_YICES

export OVERRIDE_BUILD OVERRIDE_LANGUAGES OVERRIDE_COMPILER OVERRIDE_DEBUG
export OVERRIDE_OPTIMIZE OVERRIDE_WARNINGS OVERRIDE_CODE_COVERAGE
export OVERRIDE_ASSERTIONS OVERRIDE_BOOST OVERRIDE_CMAKE OVERRIDE_DLIB
export OVERRIDE_DOXYGEN OVERRIDE_EDG OVERRIDE_MAGIC OVERRIDE_PYTHON
export OVERRIDE_QT OVERRIDE_READLINE OVERRIDE_SQLITE OVERRIDE_WT
export OVERRIDE_YAML OVERRIDE_YICES

echo
expect_yes "Shall I start running tests? " || exit 0

testNumber=0
while true; do
    testNumber=$[testNumber+1]
    (figlet "Test $testNumber" || banner "Test $testNumber" || (echo; echo "Test $testNumber"; echo)) 2>/dev/null
    matrixRunOneTest.sh
    sleep 1                     # so we have time for Ctrl-C if something is royally messed up over slow link
done
