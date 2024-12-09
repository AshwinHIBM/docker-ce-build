#!/bin/bash
set -u

PATH_CI="${PWD}/upstream-master-ci"
echo "${PATH_CI}"
export PATH_CI

echo "Prow Job to run CI tests on the Docker packages"
# Go to the workdir
echo "* Starting dockerd and waiting for it *"
${PWD}/dockerctl.sh start

# Get the env files
echo "** Set up (env files) **"
chmod ug+x ${PATH_CI}/get-env-ci.sh && ${PATH_CI}/get-env-ci.sh

set -o allexport

echo "*** Build dev image ***"
chmod ug+x ${PATH_CI}/build-dev-image.sh && ${PATH_CI}/build-dev-image.sh