#!/bin/bash
set -u

# Path to the scripts
PATH_CI="${PWD}/upstream-master-ci"
export PATH_CI
DATE=`date +%d%m%y-%H%M`

REPO_OWNER="ppc64le-cloud"
REPO_NAME="docker-ce-build"
PATH_SCRIPTS="/home/prow/go/src/github.com/${REPO_OWNER}/${REPO_NAME}"
echo DATE=\"${DATE}\" 2>&1 | tee ${PATH_SCRIPTS}/env/date.list

echo "Prow Job to run CI tests on the Docker packages"

${PWD}/dockerctl.sh start

# Get the env files
echo "** Set up (env files) **"
chmod ug+x ${PATH_CI}/get-env-ci.sh && ${PATH_CI}/get-env-ci.sh

echo "*** Check Config ***"
chmod ug+x ${PATH_CI}/info.sh
${PATH_CI}/info.sh

if [[ $? == 0 ]]; then 
    chmod ug+x ./setup-pj-trigger.sh
    ./setup-pj-trigger.sh -r ppc64le-cloud/docker-ce-build
else
    echo "The kernel is not suitable to run Docker."
    exit 1
fi
