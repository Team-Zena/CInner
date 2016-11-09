#!/bin/bash
# config vars for cinner

# Define the git repository for which we fetch and run test cases for
REPO_NAME=repo.example.com
REPO_LOC=/www/${REPO_NAME}
REPO_GIT=${REPO_LOC}/.git

# Location where cinner is present and stores it logs
CINNER_LOC=/www/cinner
SCRIPT_OUTPUT_DIR=${CINNER_LOC}/log
BUILD_LOG_NAME=cinner_build_log_${REPO_NAME}.txt
BUILD_LOG=${SCRIPT_OUTPUT_DIR}/${BUILD_LOG_NAME}
LOCK_FILE=${SCRIPT_OUTPUT_DIR}/status.lck

# Web URL for accessing cinner log from Github
LOG_URL_BASE="https://ci.example.com/log"

# Github webhook configuration
GITHUB_TOKEN="12345678"
GITHUB_API_REMOTE="https://api.github.com/repos/username/repo"

# Config related to the test suite we run
CODECEPT_CONF=${REPO_LOC}/codeception.yml

# Options related to running the script
# NOTE: 1 is equivalent to false, 0 is true
QUIET="--quiet"
CODECEPT_ARG=""
VERBOSE=1
RERUN_TASK=1
RESEND_MSG=1
RERUN_ON_FAILURE=1

# How long should the script wait if another instance is executing (in seconds)
WAIT_TIMEOUT=300
