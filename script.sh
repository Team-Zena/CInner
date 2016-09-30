#!/bin/bash
# script.sh: script to cd to a git repo, fetch specified commit, switch to it, run tests and post the output

# config vars
REPO_NAME=ActozenQC3
REPO_LOC=/var/repo/${REPO_NAME}
REPO_GIT=${REPO_LOC}/.git
CODECEPT_CONF=${REPO_LOC}/codeception.yml
SCRIPT_OUTPUT_DIR=/var/log/cinner
SCRIPT_OUTPUT=${SCRIPT_OUTPUT_DIR}/CInner_run_${REPO_NAME}_$(date +%s).log
COMMIT=$1

# check cmd line
if [ -z ${COMMIT} ]; then
	echo "commit to checkout not specified!"
	exit 1
fi

# other checks


# checkout specified commit
#cd "${GIT_REPO}"
git --git-dir=${REPO_GIT} --work-tree=${REPO_LOC} fetch origin "${COMMIT}" --quiet
git --git-dir=${REPO_GIT} --work-tree=${REPO_LOC} checkout "${COMMIT}" --quiet

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
git --git-dir=${REPO_GIT} --work-tree=${REPO_LOC} checkout master --quiet
