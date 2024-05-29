#!/bin/bash
set -u

begin=$SECONDS

echo "Prow Job to run integration tests on the Docker packages"

${PWD}/dockerctl.sh start

set -o allexport
export PATH_CI="${PWD}/upstream-master-ci"
# Get the env files
echo "** Set up (env files) **"
chmod ug+x ${PWD}/get-env.sh && ${PWD}/get-env.sh
chmod ug+x ${PATH_CI}/get-env-ci.sh && ${PATH_CI}/get-env-ci.sh

echo "*** Build dev image ***"
chmod ug+x ${PATH_CI}/build-dev-image.sh && ${PATH_CI}/build-dev-image.sh

exit_code_build=$?
echo "Exit code build : ${exit_code_build}"

if [[ $? != 0 ]]; then
    echo "Building dev image failed."
    exit 1
fi

echo "*** Run integration tests ***"
chmod ug+x ${PATH_CI}/integration-tests.sh && ${PATH_CI}/integration-tests.sh

exit_code_integration=$?
echo "Exit code integration tests : ${exit_code_integration}"

duration=$(( $SECONDS - $begin ))
echo "DURATION INTEGRATION TEST $(( $duration / 60 )) minutes and $(( $duration % 60 )) seconds elapsed." 
exit $exit_code_integration