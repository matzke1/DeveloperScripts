#!/bin/bash

# Matrix repository that holds what should be tested.  This should be a quiescent repo -- not one used for development. The
# current branch is assumed to be the one to test after merging in other commits.
MATRIX_REPOSITORY="$HOME/GS-CAD/ROSE/matrix/source-repo"

# Update the matrix repository. This assumes that we're on a branch that should be tested, and prior to testing we should
# from a remote named "testing"
PULL_REPOSITORY="https://github.com/rose-compiler/rose-develop"
PULL_BRANCH="master"

dir0="${0%/*}"
arg0="${0##*/}"

# Create or update the repository
if [ ! -d "$MATRIX_REPOSITORY" ]; then
    (set -x; git clone -b "$PULL_BRANCH" "$PULL_REPOSITORY" "$MATRIX_REPOSITORY") || exit 1
else
    (
	set -ex
	cd "$MATRIX_REPOSITORY"
	git fetch origin
	git merge FETCH_HEAD
    ) || exit 1
fi

# Run ROSE's "build" script before running any tests
(
    set -ex
    cd "$MATRIX_REPOSITORY"
    ./build
) || exit 1

# Run tests
while true; do
    $dir0/matrixRunOneTest.sh || exit 1
    sleep 1 # time for control-C
done
