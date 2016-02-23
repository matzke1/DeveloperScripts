#!/bin/bash


########################################################################################################################
# User configuration.     This section has settings that can be adjusted by the user.

# The name of the database that stores the results.
: ${DATABASE:="postgresql://rose:fcdc7b4207660a1372d0cd5491ad856e@www.hoosierfocus.com/rose_matrix"}

# The directory (need not exist yet) where building occurs and where log files and artifacts are kept.
: ${WORKSPACE="$HOME/junk/matrix-testing"}

# Whether to save tarballs of the build directories after each test (set to "yes" or empty). The tarballs are placed in
# the $WORKSPACE directory.
: ${SAVE_BUILD_DIR:=}

# The directory containing the ROSE source code.  This should probably not be a directory that you're actively editing.
: ${ROSE_SRC:=$HOME/GS-CAD/ROSE/matrix/source-repo}

# The ROSE project build directory that contains the matrix testing tools, configured with RMC. It should have a
# corresponding source directory where things like shell scripts would exist. The ROSE_TOOLS_SRC is the empty string
# then it will be obtained by running an rmc command in the build directory.
: ${ROSE_TOOLS:=$HOME/GS-CAD/ROSE/matrix/tools-build/projects/MatrixTesting}
: ROSE_TOOLS_SRC

# Maximum parallelism switch for "make" commands. If this is empty then "rmc make" uses the maximum parallelism for
# the machine where it's running.  None empty values should include the "-j" part of the switch, as in "-j20"
: ${MAX_PARALLELISM_SWITCH:=}

# The list of steps. Each step also has a function named "run_${STEP}_commands". If the function fails then the test status
# is set to $STEP.  If all functions pass then the status is the last step that was started (thus the last step should
# typically not do anything).  The functions are run with the CWD being the top of the ROSE build tree. The "setup" step
# always happens before any others and is reponsible for creating the build directories and checking the environment.
BUILD_STEPS=(configure library-build libtest-build libtest-check project-bintools end)

run_configure_commands() {
    # Runs either autoconf or cmake to generate the makefiles
    rmc config --dry-run >>"$COMMAND_DRIBBLE" 2>&1
    rmc config --dry-run && rmc config
}

run_library-build_commands() {
    # The "rmc make" is a frontend to "make" that builds specified targets one at a time and knows how much parallelism
    # to use. The extra "make -j1" command is so that error messages are readable if the parallel one fails.
    rmc make -C src $MAX_PARALLELISM_SWITCH --dry-run >>"$COMMAND_DRIBBLE" 2>&1
    rmc make -C src $MAX_PARALLELISM_SWITCH || rmc make -C src -j1
}

run_libtest-build_commands() {
    rmc make -C tests $MAX_PARALLELISM_SWITCH --dry-run >>"$COMMAND_DRIBBLE" 2>&1
    rmc make -C tests $MAX_PARALLELISM_SWITCH || rmc make -C tests -j1
}
    
run_libtest-check_commands() {
    rmc make -C tests $MAX_PARALLELISM_SWITCH --dry-run check >>"$COMMAND_DRIBBLE" 2>&1
    rmc make -C tests $MAX_PARALLELISM_SWITCH check || rmc make -C tests -j1 check
}

run_project-bintools_commands() {
    rmc make -C projects/BinaryAnalysisTools $MAX_PARALLELISM_SWITCH --dry-run check >>"$COMMAND_DRIBBLE" 2>&1
    rmc make -C projects/BinaryAnalysisTools $MAX_PARALLELISM_SWITCH check || rmc make -C BinaryAnalysisTools -j1 check
}

run_end_commands() {
    echo "success!"
}

# End of user-configuration
########################################################################################################################




























# Other global variables
arg0=${0##*/}
dir0=${0%/*}

# Distinctive string that separates one section of output from another.
OUTPUT_SECTION_SEPARATOR='=================-================='

TEST_SUBDIR="matrix-test-$$"
LOG_FILE="$WORKSPACE/$TEST_SUBDIR.log"
COMMAND_DRIBBLE="$WORKSPACE/$TEST_SUBDIR.cmds"
TEST_DIRECTORY="$WORKSPACE/$TEST_SUBDIR"
TARBALL="$WORKSPACE/$TEST_SUBDIR.tar.gz"

# Get the source directory corresponding to the tools build directory.
if [ "$ROSE_TOOLS_SRC" = "" ]; then
    ROSE_TOOLS_SRC=$(rmc -C "$ROSE_TOOLS" bash -c 'echo $RG_SRC')
    if [ "$ROSE_TOOLS_SRC" = "" ]; then
	echo "$arg0: cannot find ROSE_TOOLS_SRC for tools build directory $ROSE_TOOLS" >&2
	exit 1
    fi
fi


########################################################################################################################
# Generate an output section heading. The heading is a single line.
output_section_heading() {
    local name="$1"
    echo "$OUTPUT_SECTION_SEPARATOR $name $OUTPUT_SECTION_SEPARATOR"
}

########################################################################################################################
# Filter output for a running command. Reads standard input and writes only a few important things to standard output.
filter_output() {
    perl -e '$|=1; while(<STDIN>) {/^$ARGV[0]\s+(.*?)\s+$ARGV[0]$/ && print "Starting next step: ", lc($1), "...\n"}' \
	"$OUTPUT_SECTION_SEPARATOR"
}

########################################################################################################################
# Send results back to the database. Arguments are passed to the matrixTestResult command.
report_results() {
    local kvpairs
    eval "kvpairs=($(rmc -C $TEST_DIRECTORY $ROSE_TOOLS_SRC/projects/MatrixTesting/matrixScanEnvironment.sh))"
    local rose_version=$(cd $ROSE_SRC && git rev-parse HEAD)
    if (cd $ROSE_SRC && git status --short |grep '^.M' >/dev/null 2>&1); then
	rose_version="$rose_version+local"
    fi
    rmc -C $ROSE_TOOLS ./matrixTestResult --database=$DATABASE "$@" \
	"${kvpairs[@]}" \
	rose="$rose_version" \
	rose_date=$(cd $ROSE_SRC && git log -n1 --pretty=format:'%ct') \
	tester="$(whoami) using $arg0"
}

########################################################################################################################
# Set up the testing directory, log files, etc.  Fails if the setup seems invalid
setup_workspace() {
    (
	set -e

	# Set up the directory where the tests are run. Removal is done this way to limit disaster if logic is wrong.
	output_section_heading "setup"
	(cd "$WORKSPACE" && rm -rf "$TEST_SUBDIR")
	mkdir "$TEST_DIRECTORY"
	cd "$TEST_DIRECTORY"

	# Obtain a configuration specification
	(
	    echo "rmc_rosesrc '$ROSE_SRC'"
	    rmc -C $ROSE_TOOLS ./matrixNextTest --format=rmc -d "$DATABASE"
	) | tee .rmc-main.cfg
	echo
	rmc echo "Basic sanity checks pass"
    ) 2>&1 |tee "$LOG_FILE" |filter_output >&2
    [ "${PIPESTATUS[0]}" -ne 0 ] && return 1

    report_results --dry-run -L 'tool(>=trace)' status=setup
}

########################################################################################################################

run_test() {
    local testid
    local t0=$(date '+%s')
    if setup_workspace; then
	# Try to run each testing step
	(
	    cd "$TEST_DIRECTORY"
	    for step in "${BUILD_STEPS[@]}"; do
		output_section_heading "$step"
		local begin=$SECONDS
		eval "(run_${step}_commands)"
		local status=$?
		local end=$SECONDS
		extended_hms $[end-begin] >>"$COMMAND_DRIBBLE"
		[ $status -ne 0 ] && break
	    done
	) 2>&1 |tee -a "$LOG_FILE" | filter_output >&2

	# Figure out final status. First check for the "success" marker; then check for the others in reverse order.
	local disposition=setup
	local sections=("${BUILD_STEPS[@]}")
	for step in success $(perl -e 'print join " ", reverse @ARGV' depend "${BUILD_STEPS[@]}"); do
	    if grep --fixed-strings "$OUTPUT_SECTION_SEPARATOR $step $OUTPUT_SECTION_SEPARATOR" "$LOG_FILE" >/dev/null; then
		disposition="$step"
		break
	    fi
	done

	# Send some info back to the database
	if [ "$disposition" != "setup" ]; then
	    local t1=$(date '+%s')
	    local duration=$[ t1 - t0 ]
	    local noutput=$(wc -l <"$LOG_FILE")
	    local nwarnings=$(grep 'warning:' "$LOG_FILE" |wc -l)
	    testid=$(report_results -L 'tool(>=info)' \
				    duration=$duration noutput=$noutput nwarnings=$nwarnings status=$disposition)
	    local abbr_output="$WORKSPACE/$TEST_SUBDIR.output"
	    tail -n 500 "$LOG_FILE" >"$abbr_output"
	    rmc -C $ROSE_TOOLS ./matrixAttachments --attach --title="Final output" $testid "$abbr_output"
	    rmc -C $ROSE_TOOLS ./matrixAttachments --attach --title="Commands" $testid "$COMMAND_DRIBBLE"
	    rmc -C $ROSE_TOOLS ./matrixErrors update
	fi
    fi

    # Clean up work space
    if [ "$SAVE_BUILD_DIR" != "" ]; then
	tar cvzf "$TARBALL" -C "$WORKSPACE" "$TEST_SUBDIR"
    fi
    (cd "$WORKSPACE" && rm -rf "$TEST_SUBDIR")

    if [ "$testid" != "" ]; then
	mv "$TARBALL" "$WORKSPACE/matrix-result-$testid.tar.gz" 2>/dev/null
	mv "$LOG_FILE" "$WORKSPACE/matrix-result-$testid.log" 2>/dev/null
	mv "$COMMAND_DRIBBLE" "$WORKSPACE/matrix-result-$testid.cmds" 2>/dev/null
    fi
}

########################################################################################################################

echo "logging to $LOG_FILE"
run_test


