#!/bin/bash
# script.sh: script to cd to a git repo, fetch specified commit, switch to it, run tests and post the output

# constants
STAT_FAIL='failure'
STAT_WAIT='pending'
STAT_PASS='success'
STAT_SENT='submitted'
STAT_DONE='executed'
STAT_TERM='terminated'

# functions
show_help() {
cat << EOF
Usage: ${0##*/} [-hvdrsf] [-c COMMIT]
Fetches the commit with specified hash, runs the test and posts the output.

    -h          display this help and exit
    -c COMMIT   commit hash
    -v          verbose mode
    -d          debug mode for codeception
    -r          rerun task(s) even if build log says they have already been executed
    -s          resend message for previously executed task(s)
    -f          rerun task(s) with debug mode enabled in case of failure
EOF
}

# to echo message, and exit
# syntax die MESSAGE
die () {
	[ -n "$1" ] && echo "$1"
	exit 1
}

# to send message to github hook via curl
# send_message STATUS MESSAGE URL
send_message () {
	local status="$1"
	local message="$2"
	local url="$3"
	local context="$4"

	# error checking
	[ -z "$status" ] && return 1
	[ -z "$context" ] && context='ci/Tests'

	# send the message
	/usr/bin/curl --silent -i -H "Authorization: token ${GITHUB_TOKEN}" \
		-d '{  "state": "'"${status}"'",  "target_url": "'"${url}"'",  "description": "'"${message}"'","context": "'"$context"'"}' \
		"${GITHUB_API_REMOTE}/statuses/${COMMIT}" >> "${REQUEST_OUTPUT}" 2>&1
}

# to check if lock is acquired by current process
check_lock () {
	if [ -f "${LOCK_FILE}" ] && [ "$(head -n 1 "${LOCK_FILE}")" = pending ]; then
		local script_pid
		script_pid=$(sed '2q;d' "${LOCK_FILE}")
		if [ "${script_pid}" = $$ ]; then
			return 0
		fi
	fi
	return 1
}

# to write to the lock file
# write_lock STATUS MESSAGE(optional)
write_lock () {
	local status="$1"

	# error checking
	[ -z "$status" ] && return 1

	echo "${status}" > "${LOCK_FILE}"
	[ -n "$2" ] && echo "$2" >> "${LOCK_FILE}"
}

# to check lock and clear it if found to be stale
clear_lock () {
	if [ -f "${LOCK_FILE}" ] && [ "$(head -n 1 "${LOCK_FILE}")" = pending ]; then
		local script_pid
		script_pid=$(sed '2q;d' "${LOCK_FILE}")
		if ! ps -p "${script_pid}" >> /dev/null; then
			# process specified is not running, ie, stale lock file
			sleep 5s
			rm "${LOCK_FILE}"
		fi
	fi
}

# to write status to build log
# write_status STATUS
write_status () {
	local status="$1"
	local time
	time=$(date +%s)

	# error checking
	[ -z "$status" ] && return 1
	[ -z "${COMMIT}" ] && return 1

	# output format
	# COMMIT	TIME	STATUS
	echo -e "${COMMIT}\t${status}\t${time}" >> "${BUILD_LOG}"
}

# to clear lock file, write_status and exit
# clear_and_exit STATUS EXIT_CODE
clear_and_exit () {
	write_status "$1"
	check_lock && write_lock "$1"
	CODE=1
	[ -n "$2" ] && CODE="$2"
	exit "${CODE}"
}

# to check if we are runnning in verbose mode
check_verbose () {
	return "$VERBOSE"
}

# to check if a variable evaluates to true
# check_var VARIABLE
check_var () {
	return "$1"
}

# to check if task has already been executed
check_execution_status () {
	[ -z "${COMMIT}" ] && return 1
	[ "${RERUN_TASK}" -eq 0 ] && return 1
	[ ! -f "${BUILD_LOG}" ] && return 1

	local commit_exec_log
	commit_exec_log=$(grep -w "${COMMIT}" "${BUILD_LOG}")
	if echo "${commit_exec_log}" | grep -q -e "${STAT_PASS}" -e "${STAT_FAIL}"; then
		return 0
	fi

	return 1
}

# to get the output of a test (one liner)
get_test_output () {
	local out
	if [ -f "${SCRIPT_OUTPUT}" ]; then
		out="$(tail -n -2 "${SCRIPT_OUTPUT}" | head -n 1)"
	fi
	echo -n "${out}"
}

# to check output of a test and set STATUS
check_and_set_test_output() {
	if tail -n -4 "${SCRIPT_OUTPUT}" | grep -q -w 'OK'; then
		STATUS="${STAT_PASS}"
	else
		STATUS="${STAT_FAIL}"
	fi
}

# to set execution status of COMMIT in build log as well as send message
set_execution_status () {
	[ -z "${COMMIT}" ] && return 1

	local retval=1
	if check_execution_status; then
		retval="$(grep -w "${COMMIT}" "${BUILD_LOG}" | while read -r line; do \
				stat=$(echo -n "$line" | grep -o -e "${STAT_FAIL}" -e "${STAT_PASS}"); \
				if [ "$stat" = "$STAT_FAIL" ] || [ "$stat" = "$STAT_PASS" ]; then
					local test_out
					test_out=$(get_test_output)
					check_var "${RESEND_MSG}" && send_message "${stat}" "${test_out}" "${LOG_URL_CODECEPT}"
					write_status "${STAT_DONE}"
					echo 0; break
				fi; done
			)"
	fi

	if [ "$retval" -eq 0 ]; then
		check_verbose && echo "Already executed task(s) for commit ${COMMIT}"
		exit 0
	fi
}

# to run a codeception test
codecept_run_test () {
	nice -n 10 "${REPO_LOC}/vendor/bin/codecept" run --html="${SCRIPT_OUTPUT_HTML}" --no-colors --ansi --config "${CODECEPT_CONF}" "${CODECEPT_ARG}" \
		> "${SCRIPT_OUTPUT}" 2>&1

	# parse output from script
	check_and_set_test_output
}

# to run the test script and set output variables
run_tests () {
	# run the test
	codecept_run_test

	# one line status
	CMD_OUTPUT_SHORT=$(get_test_output)

	# if test script failed, rerun test with debug enabled
	if [ "${STATUS}" = ${STAT_FAIL} ] && check_var "${RERUN_ON_FAILURE}"; then
		check_verbose && echo "re-running tests with debug mode on..."
		set_codecept_mode 'debug'
		codecept_run_test
		send_message "${STATUS}" "${CMD_OUTPUT_SHORT}" "${LOG_URL_SCRIPT}" "ci/Tests/failure-debug"
		set_codecept_mode 'normal'
	fi

	# send message to github with status
	send_message "${STATUS}" "${CMD_OUTPUT_SHORT}" "${LOG_URL_CODECEPT}"
}

# to set the static (hardcoded) post commit vars
set_static_postcommit_vars() {
	SCRIPT_OUTPUT_NAME=cinner_run_${COMMIT}_${REPO_NAME}.txt
	REQUEST_OUTPUT_NAME=cinner_request_${COMMIT}_${REPO_NAME}.txt
	SCRIPT_OUTPUT_HTML_NAME=codecept_report_${COMMIT}_${REPO_NAME}.html
	PARENT_OUTPUT_NAME=script_output_${COMMIT}_${REPO_NAME}.txt
}

# to set the dynamic (derived) post commit vars
set_dynamic_postcommit_vars() {
	SCRIPT_OUTPUT="${SCRIPT_OUTPUT_DIR}/${SCRIPT_OUTPUT_NAME}"
	REQUEST_OUTPUT="${SCRIPT_OUTPUT_DIR}/${REQUEST_OUTPUT_NAME}"
	SCRIPT_OUTPUT_HTML="${SCRIPT_OUTPUT_DIR}/${SCRIPT_OUTPUT_HTML_NAME}"
	PARENT_OUTPUT="${SCRIPT_OUTPUT_DIR}/${PARENT_OUTPUT_NAME}"

	LOG_URL_SCRIPT="${LOG_URL_BASE}/${SCRIPT_OUTPUT_NAME}"
	LOG_URL_REQUEST="${LOG_URL_BASE}/${REQUEST_OUTPUT_NAME}"
	LOG_URL_CODECEPT="${LOG_URL_BASE}/${SCRIPT_OUTPUT_HTML_NAME}"
	LOG_URL_PARENT="${LOG_URL_BASE}/${PARENT_OUTPUT_NAME}"
}

# to set relevant variables once the COMMIT variable has been redefined
set_postcommit_vars() {
	set_static_postcommit_vars
	set_dynamic_postcommit_vars
}

# to set debugging vars for codeception
set_codecept_debug_vars() {
	SCRIPT_OUTPUT_NAME=cinner_run_debug_${COMMIT}_${REPO_NAME}.txt
	REQUEST_OUTPUT_NAME=cinner_request_debug_${COMMIT}_${REPO_NAME}.txt
	SCRIPT_OUTPUT_HTML_NAME=codecept_report_debug_${COMMIT}_${REPO_NAME}.html
	PARENT_OUTPUT_NAME=script_output_debug_${COMMIT}_${REPO_NAME}.txt
}

# to set codeception mode to normal or debug
set_codecept_mode() {
	local mode=normal
	if [ "$1" == 'debug' ]; then
		CODECEPT_ARG="--debug"
		set_codecept_debug_vars
	else
		CODECEPT_ARG=
		set_static_postcommit_vars
	fi
	set_dynamic_postcommit_vars
}

# to write and send initial status
set_initial_status() {
	send_message "${STAT_WAIT}" "About to run the tasks" "${LOG_URL_SCRIPT}"
	write_status "${STAT_WAIT}"
}

# To fetch remote commit and checkout using git
git_fetch_and_checkout() {
	/usr/bin/git --git-dir="${REPO_GIT}" --work-tree="${REPO_LOC}" fetch origin ${QUIET} || clear_and_exit "${STAT_TERM}"
	/usr/bin/git --git-dir="${REPO_GIT}" --work-tree="${REPO_LOC}" reset --hard "${COMMIT}" ${QUIET} || clear_and_exit "${STAT_TERM}"
}

# IMPORTANT: set config vars before parsing cmd line args
. ./config_vars.sh || die "unable to set config variables"

# NOTE: Overriding built-in functions
[ -f ./functions_override.sh ] && . ./functions_override.sh

# cmd line args
while getopts ":c:vdrsfh" opt; do
  case $opt in
    c)
        COMMIT=$OPTARG
      ;;
    v)
        QUIET=""
	VERBOSE=0
      ;;
    d)
	CODECEPT_ARG="--debug"
      ;;
    r)
	RERUN_TASK=0
      ;;
    s)
	RESEND_MSG=0
      ;;
    f)
	RERUN_ON_FAILURE=0
      ;;
    h)
        show_help
        exit 0
      ;;
    \?)
        show_help >&2
        exit 1
      ;;
    :)
      echo "Option -$OPTARG requires an argument." >&2
      exit 1
      ;;
  esac
done

# check variables
if [ -z "${COMMIT}" ]; then
        die "commit to checkout not specified!"
fi

# set some post commit vars
set_postcommit_vars

# check if task has already been executed
set_execution_status

# SIGNAL HANDLING
trap 'check_verbose && echo "exiting..."; write_status "${STAT_TERM}"; check_lock && write_lock "${STAT_TERM}"; trap - INT; kill -INT $$' INT

# CONCURRENCY CONTROL
# clear lock if stale
clear_lock
# now check for pending tasks
START_TIME=$(date +%s)
ADD_TIME=${WAIT_TIMEOUT}
END_TIME=$((START_TIME + ADD_TIME))
while [ "$START_TIME" -le $END_TIME ]; do
	if [ -f "${LOCK_FILE}" ] && [ "$(head -n 1 "${LOCK_FILE}")" = pending ]; then
		check_verbose && echo "[${START_TIME}] [pid $$] waiting for clearance..."
		sleep 30s
		START_TIME=$(date +%s)
	else
		write_lock "${STAT_WAIT}" "$$"
		break
	fi
done

if [ "$START_TIME" -gt $END_TIME ]; then
	# TIME UP
	send_message "${STAT_WAIT}" "Build not run due to pending test(s)" "${LOG_URL_PARENT}"
	die "time out"
fi

# set status as pending
set_initial_status

# checkout specified commit
check_verbose && echo "fetching and checking out via git..."
git_fetch_and_checkout

# pre-run tasks


# run specified script
check_verbose && echo "running test script..."
run_tests

# set final status
write_status "${STATUS}"
check_verbose && echo "test complete, status: $STATUS"

# CLEAR THE STATUS FILE for next build
write_lock "${STAT_DONE}"

exit 0
