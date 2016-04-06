#!/bin/bash
arg0=${0##*/}
dir0=${0%/*}

########################################################################################################################
# User configuration.     This section has settings that can be adjusted by the user.

# The name of the database that stores the results.
: ${DATABASE:="postgresql://rose:fcdc7b4207660a1372d0cd5491ad856e@www.hoosierfocus.com/rose_matrix"}

# Name of this test sequence, or the person/software doing the testing
: ${TEST_SEQUENCE:="$(whoami) using $arg0"}

# URL of database or file that stores the configuration space to be tested.
: ${CONFIGURATION_SPACE_URL:="$DATABASE"}

# URL of database or email address to which test results are sent.  For emails, use the HTML format "mailto:address".
: ${RESULTS_URL:="$DATABASE"}

# The directory (need not exist yet) where building occurs and where log files and artifacts are kept.
: ${WORKSPACE:="$HOME/junk/matrix-testing"}

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

# Restrict compilers, ect. to only those in these lists. This helps speed up processing because it means this script
# chooses the dependencies instead of letting the database choose them. If we let the database choose them and the
# database has many more that what we have, then we spend most our time failing in the very first consistency check. The
# names of these variables correspond to various RMC configuration statements.
#
# These variables should be space-separated values, like OVERRIDE_BOOST="1.50 1.51". This precludes us from having
# spaces within the values themselves, but if this proves to be a problem we can change the delimiter to something else.
# Unfortunately we can't pass shell arrays directly to subshells, otherwise this would be easier.
: ${OVERRIDE_PARALLELISM:=}
: ${OVERRIDE_BUILD:=}
: ${OVERRIDE_LANGUAGES:=}
: ${OVERRIDE_COMPILER:=}
: ${OVERRIDE_DEBUG:=}
: ${OVERRIDE_OPTIMIZE:=}
: ${OVERRIDE_WARNINGS:=}
: ${OVERRIDE_CODE_COVERAGE:=}
: ${OVERRIDE_ASSERTIONS:=}
: ${OVERRIDE_BOOST:=}
: ${OVERRIDE_CMAKE:=}
: ${OVERRIDE_DLIB:=}
: ${OVERRIDE_DOXYGEN:=}
: ${OVERRIDE_EDG:=}
: ${OVERRIDE_MAGIC:=}
: ${OVERRIDE_PYTHON:=}
: ${OVERRIDE_QT:=}
: ${OVERRIDE_READLINE:=}
: ${OVERRIDE_SQLITE:=}
: ${OVERRIDE_WT:=}
: ${OVERRIDE_YAML:=}
: ${OVERRIDE_YICES:=}


# The list of steps. Each step also has a function named "run_${STEP}_commands". If the function fails then the test status
# is set to $STEP.  If all functions pass then the status is the last step that was started (thus the last step should
# typically not do anything).  The functions are run with the CWD being the top of the ROSE build tree. The "setup" step
# always happens before any others and is reponsible for creating the build directories and checking the environment.
BUILD_STEPS=(
    configure
    library-build
    libtest-build
    libtest-check
    projects-robb
    projects-justin
    projects-dan
    projects-markus
    projects-peihung
    projects-leo
    end
)

# Commands to be run for each step. See BUILD_STEPS above.  Standard error and standard output are both redirected to log
# files that may get transferred to the central database. If you really need something to show up in the terminal running
# this script then send it to file descriptor 99, as in "echo message for operator >&99" (but beware that matrix testing
# often runs unattended, so your message will likely go unnoticed). To send a message to the log file and the terminal
# use "echo message |tee /proc/self/fd/99"
run_configure_commands() {
    # Runs either autoconf or cmake to generate the makefiles
    rmc config --dry-run >>"$COMMAND_DRIBBLE" 2>&1
    rmc config --dry-run && rmc config
}

run_library-build_commands() {
    # The "rmc make" is a frontend to "make" that builds specified targets one at a time and knows how much parallelism
    # to use. The extra "make -j1" command is so that error messages are readable if the parallel one fails.
    rmc make -C src --dry-run >>"$COMMAND_DRIBBLE" 2>&1
    rmc make -C src || rmc make -C src -j1
}

run_libtest-build_commands() {
    rmc make -C tests --dry-run >>"$COMMAND_DRIBBLE" 2>&1
    rmc make -C tests || rmc make -C tests -j1
}
    
run_libtest-check_commands() {
    rmc make -C tests --dry-run check >>"$COMMAND_DRIBBLE" 2>&1
    rmc make -C tests check || rmc make -C tests -j1 check
}

run_projects-robb_commands() {
    rmc make -C projects check-projects-robb --dry-run check >>"$COMMAND_DRIBBLE" 2>&1
    rmc make -C projects check-projects-robb || rmc make -C projects -j1 check-projects-robb
}

run_projects-justin_commands() {
    rmc make -C projects check-projects-justin --dry-run check >>"$COMMAND_DRIBBLE" 2>&1
    rmc make -C projects check-projects-justin || rmc make -C projects -j1 check-projects-justin
}

run_projects-dan_commands() {
    rmc make -C projects check-projects-dan --dry-run check >>"$COMMAND_DRIBBLE" 2>&1
    rmc make -C projects check-projects-dan || rmc make -C projects -j1 check-projects-dan
}

run_projects-markus_commands() {
    rmc make -C projects check-projects-markus --dry-run check >>"$COMMAND_DRIBBLE" 2>&1
    rmc make -C projects check-projects-markus || rmc make -C projects -j1 check-projects-markus
}

run_projects-peihung_commands() {
    rmc make -C projects check-projects-peihung --dry-run check >>"$COMMAND_DRIBBLE" 2>&1
    rmc make -C projects check-projects-peihung || rmc make -C projects -j1 check-projects-peihung
}

run_projects-leo_commands() {
    rmc make -C projects check-projects-leo --dry-run check >>"$COMMAND_DRIBBLE" 2>&1
    rmc make -C projects check-projects-leo || rmc make -C projects -j1 check-projects-leo
}

run_end_commands() {
    echo "success!"
}

# End of user-configuration
########################################################################################################################





























# Distinctive string that separates one section of output from another.
OUTPUT_SECTION_SEPARATOR='=================-================='

TEST_SUBDIR="matrix-test-pid$$"
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
# Recompute/move file names based on test number.
adjust_file_names() {
    local test_id="$1"

    local new_log_file="$WORKSPACE/matrix-test-$test_id.log"
    local new_command_dribble="$WORKSPACE/matrix-test-$test_id.cmds"
    local new_tarball="$WORKSPACE/matrix-test-$test_id.tar.gz"

    [ -r "$LOG_FILE" -a "$LOG_FILE" != "$new_log_file" ] && \
	mv "$LOG_FILE" "$new_log_file"
    [ -r "$COMMAND_DRIBBLE" -a "$COMMAND_DRIBBLE" != "$new_command_dribble" ] && \
	mv "$COMMAND_DRIBBLE" "$new_command_dribble"
    [ -r "$TARBALL" -a "$TARBALL" != "$new_tarball" ] && \
	mv "$TARBALL" "$new_tarball"

    LOG_FILE="$new_log_file"
    COMMAND_DRIBBLE="$new_command_dribble"
    TARBALL="$new_tarball"
}

########################################################################################################################
# Convert number of seconds to a string, like "9 hours 39 minutes 49 seconds"
seconds_to_hms() {
    local sec="$1"
    if [ $sec -ge 86400 ]; then
	local ndays=$[sec/86400]
	sec=$[sec-ndays*86400]
	local units="days"
	[ "$ndays" -eq 1 ] && units="day"
	echo -n "$ndays $units "
    fi
    if [ $sec -ge 3600 ]; then
	local nhours=$[sec/3600]
	sec=$[sec-nhours*3600]
	local units="hours"
	[ "$nhours" -eq 1 ] && units="hour"
	echo -n "$nhours $units ";
    fi
    if [ $sec -ge 60 ]; then
	local nmins=$[sec/60]
	sec=$[sec-nmins*60]
	local units="minutes"
	[ "$nmins" -eq 1 ] && units="minute"
	echo -n "$nmins $units ";
    fi

    local units="seconds"
    [ "$sec" -eq 1 ] && units="second"
    echo "$sec $units"
}

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
# Send results back to the database. Arguments are passed to the matrixTestResult command. Echos only the test ID.
report_results() {
    local database="$1"; shift
    local kvpairs
    eval "kvpairs=($(rmc -C $TEST_DIRECTORY $ROSE_TOOLS_SRC/projects/MatrixTesting/matrixScanEnvironment.sh))"
    local rose_version=$(cd $ROSE_SRC && git rev-parse HEAD)

    local dry_run= command_output=
    while [ "$#" -gt 0 ]; do
	local arg="$1"; shift
	case "$arg" in
            --dry-run)
		dry_run="--dry-run"
		;;
	    --command-output=*)
		command_output="${arg#--command-output=}"
		;;
	    *=*)
		kvpairs=("${kvpairs[@]}" "$arg")
		;;
	    *)
		echo "$arg0: report_results unknown argument: $arg" >&2
		;;
	esac
    done

    if (cd $ROSE_SRC && git status --short |grep '^.M' >/dev/null 2>&1); then
	rose_version="$rose_version+local"
    fi

    local testid=
    if [ "${database#mailto:}" = "$database" ]; then
	# The database is available, so use it.
	testid=$(rmc -C $ROSE_TOOLS ./matrixTestResult --database="$database" -L 'tool(>=trace)' $dry_run \
		     "${kvpairs[@]}" \
		     rose="$rose_version" \
		     rose_date=$(cd $ROSE_SRC && git log -n1 --pretty=format:'%ct') \
		     tester="$TEST_SEQUENCE")
	if [ "$dry_run" = "" ]; then
	    if [ "$testid" = "" ]; then
		echo "$arg0: matrixTestResult faild to insert the test" >&2
		return 1
	    fi
	    rmc -C "$ROSE_TOOLS" ./matrixAttachments --attach --title="Commands" $testid "$COMMAND_DRIBBLE"
	    if [ "$command_output" != "" ]; then
		rmc -C "$ROSE_TOOLS" ./matrixAttachments --attach --title="Final output" $testid "$command_output"
	    fi
	    rmc -C $ROSE_TOOLS ./matrixErrors update $testid
	    adjust_file_names $testid
	fi

    elif [ "$is_dry_run" = "" ]; then
	# There is no database and we should email the results somewhere.
	local address="${database#mailto:}"
	local subject="matrix test result"

	(
	    local pair
	    for pair in "${kvpairs[@]}" "$@"; do
		echo "$pair"
	    done
	    echo "rose=$rose_version"
	    echo "rose_date=$(cd $ROSE_SRC && git log -n1 --pretty=format:'%ct')"
	    echo "tester=$TEST_SEQUENCE"
	    echo
	    echo "==== COMMANDS BEGIN ===="
	    base64 <"$COMMAND_DRIBBLE"
	    echo "==== COMMANDS END ===="
	    echo
	    if [ "$command_output" != "" ]; then
		echo "==== COMMAND OUTPUT BEGIN ===="
		base64 <"$command_output"
		echo "==== COMMAND OUTPUT END ===="
	    fi
	) | mail -s "$subject" "$address"
	testid="(not assigned yet)"
	echo "results mailed to $address"
    fi

    echo "$testid"
}

########################################################################################################################
# Modify a .rmc-main.cfg file (in the CWD) by replacing a statement with a random value.  If the choices are empty then
# don't make any modifications.
modify_config() {
    local statement="$1"; shift
    local choices=("$@")
    [ "${#choices[@]}" -eq 0 ] && return 0
    local random_choice="${choices[ RANDOM % ${#choices[@]} ]}"
    sed --in-place "s%^[ \t]*$statement[ \t].*%$statement $random_choice%" .rmc-main.cfg
    if ! grep "^ *$statement " .rmc-main.cfg >/dev/null; then
	echo "$statement $random_choice" >>.rmc-main.cfg
    fi
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

	(
	    echo "rmc_rosesrc '$ROSE_SRC'"
	    rmc -C $ROSE_TOOLS ./matrixNextTest --format=rmc --database="$CONFIGURATION_SPACE_URL"
	) >.rmc-main.cfg

	# Maybe we should override some things in the config -- the config we get from the database is just a hint.
	modify_config rmc_build     	$OVERRIDE_BUILD
	modify_config rmc_languages 	$OVERRIDE_LANGUAGES
	modify_config rmc_compiler  	$OVERRIDE_COMPILER
	modify_config rmc_debug     	$OVERRIDE_DEBUG
	modify_config rmc_optimize  	$OVERRIDE_OPTIMIZE
	modify_config rmc_warnings  	$OVERRIDE_WARNINGS
	modify_config rmc_code_coverage $OVERRIDE_CODE_COVERAGE
	modify_config rmc_parallelism   $OVERRIDE_PARALLELISM
	modify_config rmc_assertions    $OVERRIDE_ASSERTIONS
	modify_config rmc_boost   	$OVERRIDE_BOOST
	modify_config rmc_cmake   	$OVERRIDE_CMAKE
	modify_config rmc_dlib    	$OVERRIDE_DLIB
	modify_config rmc_doxygen 	$OVERRIDE_DOXYGEN
	modify_config rmc_edg      	$OVERRIDE_EDG
	modify_config rmc_magic    	$OVERRIDE_MAGIC
	modify_config rmc_python   	$OVERRIDE_PYTHON
	modify_config rmc_qt       	$OVERRIDE_QT
	modify_config rmc_readline 	$OVERRIDE_READLINE
	modify_config rmc_sqlite   	$OVERRIDE_SQLITE
	modify_config rmc_wt       	$OVERRIDE_WT
	modify_config rmc_yaml     	$OVERRIDE_YAML
	modify_config rmc_yices    	$OVERRIDE_YICES
	cat .rmc-main.cfg

	rmc echo "RMC basic sanity checks pass" 2>&1 |tee /proc/self/fd/99
	exit ${PIPESTATUS[0]}

    ) 99>&2 2>&1 |tee "$LOG_FILE" |filter_output >&2
    [ "${PIPESTATUS[0]}" -ne 0 ] && return 1

    # Report what we'll eventually be sending back to the server.
    report_results "$CONFIGURATION_SPACE_URL" --dry-run status=setup
}

########################################################################################################################

run_test() {
    local testid
    local t0=$(date '+%s')
    local begin=$SECONDS
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
		seconds_to_hms $[end-begin] >>"$COMMAND_DRIBBLE"
		[ $status -ne 0 ] && break
	    done
	) 99>&2 2>&1 |tee -a "$LOG_FILE" | filter_output >&2

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
	    local abbr_output="$WORKSPACE/$TEST_SUBDIR.output"
	    tail -n 500 "$LOG_FILE" >"$abbr_output"
	    testid=$(report_results "$RESULTS_URL" --command-output="$abbr_output" \
				    duration=$duration noutput=$noutput nwarnings=$nwarnings status=$disposition)
	fi
    fi

    # Clean up work space
    if [ "$SAVE_BUILD_DIR" != "" ]; then
	tar cvzf "$TARBALL" -C "$WORKSPACE" "$TEST_SUBDIR"
    fi
    (cd "$WORKSPACE" && rm -rf "$TEST_SUBDIR")

    local end=$SECONDS
    echo "Test took $(seconds_to_hms $[end - begin])"
}

########################################################################################################################

date
echo "logging to $LOG_FILE"
run_test


