#!/bin/bash
# script.sh: script to cd to a git repo, fetch specified commit, switch to it, run tests and post the output

# config vars
REPO_NAME=ActozenQC3
REPO_LOC=/var/repo/${REPO_NAME}
SCRIPT_OUTPUT=/tmp/CInner_run_${REPO_NAME}_$(date +%s).txt
COMMIT=$1

# check cmd line
if [ -z ${COMMIT} ]; then
	echo "commit to checkout not specified!"
	exit 1
fi

# other checks


# checkout specified commit
cd "${GIT_REPO}"
git fetch "${COMMIT}"
git checkout "${COMMIT}"

# pre-run tasks

# set status as pending

# run specified script
${REPO_LOC}/vendor/bin/codecept run api --quiet --no-colors > "${SCRIPT_OUTPUT}" 2>&1

# parse output from script

# set final status
