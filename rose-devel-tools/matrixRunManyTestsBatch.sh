#!/bin/bash

# This is the script used by docker containers to run the matrix tests.
# See https://github.com/matzke1/rose-docker for docker image definitions.

# Use only available compilers
compilers=()
# for cxx_spec in $(spock-ls -1 c++-compiler); do
#     triplet=$(spock-shell --with $cxx_spec c++ --spock-triplet)
#     cxx_vendor=$(echo "$triplet" |cut -d: -f1)
#     cxx_lang=$(echo "$triplet" |cut -d: -f2)
#     cxx_version=$(echo "$triplet" |cut -d: -f3)
# 
#     [ "$cxx_vendor" = "gnu" ] && cxx_vendor=gcc
#     rmc_cxx="${cxx_vendor}-${cxx_version}-${cxx_lang}"
# 
#     compilers=("${compilers[@]}" "$rmc_cxx")
# done

mkdir -p $HOME/junk/matrix-testing

while true; do
    env \
	ROSE_SRC=$HOME/rose-source \
	ROSE_TOOLS=$HOME/matrix-tools-build/projects/MatrixTesting \
	VERBOSE=yes \
	OVERRIDE_COMPILER="${compilers[*]}" \
	OVERRIDE_DOXYGEN=none \
	OVERRIDE_JAVA=none \
	OVERRIDE_READLINE=none \
	$HOME/DeveloperScripts/rose-devel-tools/matrixRunOneTest.sh

    sleep 1
done
