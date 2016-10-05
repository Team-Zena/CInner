#!/bin/bash
# script.sh: script to cd to a git repo, fetch specified commit, switch to it, run tests and post the output

# Curl request sample: curl -i -H 'Authorization: token dc7229feb1a12c07927691db03e02587f8712967' -d '{  "state": "failure",  "target_url": "https://ngrok.example.com/build/fail1234",  "description": "Beta tumse na ho payega","context": "ci/custom/ngrok"}' https://api.github.com/repos/vaibhav-kaushal/Spoon-Knife/statuses/1b500a33c7b87561189d3f321e7293018c15ff9f

# config vars
REPO_NAME=h3.example.com
REPO_LOC=/www/${REPO_NAME}
REPO_GIT=${REPO_LOC}/.git
CODECEPT_CONF=${REPO_LOC}/codeception.yml
#SCRIPT_OUTPUT_DIR=/var/log/cinner
CINNER_LOC=$(pwd)
SCRIPT_OUTPUT_DIR=${CINNER_LOC}/log
SCRIPT_OUTPUT_NAME=CInner_run_${REPO_NAME}_$(date +%s).log
SCRIPT_OUTPUT=${SCRIPT_OUTPUT_DIR}/${SCRIPT_OUTPUT_NAME}
LOG_URL="http://ci.health-zen.com/log/${SCRIPT_OUTPUT_NAME}"
QUIET=" --quiet "
CODECEPT_ARG=""
VERBOSE=0

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
	CODECEPT_ARG="--debug"
	VERBOSE=1
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
[ $VERBOSE -eq 1 ] && echo "fetching and checking out via git..."
git --git-dir=${REPO_GIT} --work-tree=${REPO_LOC} fetch origin ${QUIET} #|| exit 1
git --git-dir=${REPO_GIT} --work-tree=${REPO_LOC} checkout -f "${COMMIT}" ${QUIET} #|| exit 1

# pre-run tasks

# set status as pending
curl --silent -i -H 'Authorization: token dc7229feb1a12c07927691db03e02587f8712967' -d '{  "state": "pending",  "target_url": "${LOG_URL}",  "description": "About to run the tasks","context": "ci/script/pending"}' https://api.github.com/repos/vaibhav-kaushal/ActozenQC3/statuses/${COMMIT} > "${SCRIPT_OUTPUT}" 2>&1

# run specified script
[ $VERBOSE -eq 1 ] && echo "running test script..."
${REPO_LOC}/vendor/bin/codecept run api --no-colors --ansi --config ${CODECEPT_CONF} ${CODECEPT_ARG} >> "${SCRIPT_OUTPUT}" 2>&1

# parse output from script
CMD_OUTPUT=$(tail -n -2 "${SCRIPT_OUTPUT}")
echo "${CMD_OUTPUT}" | grep -q 'FAILURES!'
if [ $? -eq 1 ]; then
	STATUS=failure
else
	STATUS=success
fi

# set final status
curl --silent -i -H 'Authorization: token dc7229feb1a12c07927691db03e02587f8712967' -d '{  "state": "${STATUS}",  "target_url": "${LOG_URL}",  "description": "${CMD_OUTPUT}","context": "ci/script/executed"}' https://api.github.com/repos/vaibhav-kaushal/ActozenQC3/statuses/${COMMIT} >> "${SCRIPT_OUTPUT}" 2>&1

[ $VERBOSE -eq 1 ] && echo "test complete, status: $STATUS"
exit 0
