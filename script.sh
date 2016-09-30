#!/bin/bash
# script.sh: script to cd to a git repo, fetch specified commit, switch to it, run tests and post the output

# config vars
REPO_NAME=ActozenQC3
REPO_LOC=/var/repo/${REPO_NAME}
REPO_GIT=${REPO_LOC}/.git
CODECEPT_CONF=${REPO_LOC}/codeception.yml
SCRIPT_OUTPUT_DIR=/var/log/cinner
SCRIPT_OUTPUT=${SCRIPT_OUTPUT_DIR}/CInner_run_${REPO_NAME}_$(date +%s).log
QUIET=" --quiet "

# functions
show_help() {
cat << EOF
Usage: ${0##*/} [-hv] [-c COMMIT]
Fetches the commit with specified hash, runs the test and posts the output.

    -h          display this help and exit
    -c COMMIT   write the result to OUTFILE instead of standard output.
    -v          verbose mode.
EOF
}

# cmd line args
while getopts ":c:vh" opt; do
  case $opt in
    c)
        COMMIT=$OPTARG
      ;;
    v)
        QUIET=""
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
if [ -z ${COMMIT} ]; then
        echo "commit to checkout not specified!"
        exit 1
fi

# checkout specified commit
git --git-dir=${REPO_GIT} --work-tree=${REPO_LOC} fetch origin "${COMMIT}" ${QUIET} #|| exit 1
git --git-dir=${REPO_GIT} --work-tree=${REPO_LOC} checkout "${COMMIT}" ${QUIET} #|| exit 1

# pre-run tasks

# set status as pending

# run specified script
${REPO_LOC}/vendor/bin/codecept run api --no-colors --ansi --config ${CODECEPT_CONF} > "${SCRIPT_OUTPUT}" 2>&1

# parse output from script
$CMD_OUTPUT=$(tail -n -2 ${SCRIPT_OUTPUT})
echo "${CMD_OUTPUT}" | grep -q 'FAILURES!'
if [ $? -eq 1 ]; then
	STATUS=failure
else
	STATUS=success
fi

# set final status

# revert to master branch
git --git-dir=${REPO_GIT} --work-tree=${REPO_LOC} checkout master ${QUIET}
