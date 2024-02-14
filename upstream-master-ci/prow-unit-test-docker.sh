#!/bin/bash
set -u

begin=$SECONDS

# Path to the scripts
PATH_CI="${PWD}/upstream-master-ci"
export PATH_CI
echo "Prow Job to run CI tests on the Docker packages"

# Go to the workdir
echo "* Starting dockerd and waiting for it *"
${PWD}/dockerctl.sh start

set -o allexport

# Get the env files
echo "** Set up (env files) **"
chmod ug+x ${PATH_CI}/get-env-ci.sh && ${PATH_CI}/get-env-ci.sh

echo "*** Build dev image ***"
chmod ug+x ${PATH_CI}/build-dev-image.sh && ${PATH_CI}/build-dev-image.sh

exit_code_build=$?
echo "Exit code build : ${exit_code_build}"

if [[ $? != 0 ]]; then
    echo "Building dev image failed."
    exit 1
fi

echo "*** Run unit tests ***"
chmod ug+x ${PATH_CI}/unit-tests.sh && ${PATH_CI}/unit-tests.sh

exit_code_unit=$?
echo "Exit code unit tests : ${exit_code_build}"

if [[ $? != 0 ]]; then
    echo "Unit tests failed to run."
    exit 1
fi

duration=$(( $SECONDS - $begin ))
echo "DURATION UNIT TEST $(( $duration / 60 )) minutes and $(( $duration % 60 )) seconds elapsed." 

exit 0