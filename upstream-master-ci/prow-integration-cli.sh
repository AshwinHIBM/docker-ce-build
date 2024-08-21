#!/bin/bash
set -u

begin=$SECONDS

echo "Prow Job to run integration CLI tests on the Docker packages"

${PWD}/dockerctl.sh start

set -o allexport
export PATH_CI="${PWD}/upstream-master-ci"
# Get the env files
echo "** Set up (env files) **"
chmod ug+x ${PATH_CI}/get-env-ci.sh && ${PATH_CI}/get-env-ci.sh
git clone https://github.com/docker/cli.git
echo "*** Run integration CLI tests ***"
chmod ug+x ${PATH_CI}/integration-cli.sh && ${PATH_CI}/integration-cli.sh

exit_code_integration_cli=$?
echo "Exit code integration CLI tests : ${exit_code_integration_cli}"

duration=$(( $SECONDS - $begin ))
echo "DURATION INTEGRATION CLI TEST $(( $duration / 60 )) minutes and $(( $duration % 60 )) seconds elapsed." 
sleep 10000
exit $exit_code_integration_cli