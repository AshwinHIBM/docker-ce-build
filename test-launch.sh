#!/bin/bash
# Script that launches tests from the repo https://github.ibm.com/powercloud/dockertest

set -eu
FILE_ENV="/workspace/env.list"
source ${FILE_ENV}
# Start the dockerd and wait for it to start
${PATH_SCRIPTS}/dockerctl.sh start

#Calling dockerinfo to trace the versions info (docker and deps)
#TODO addsome automated checks to make sure we are testing the proper package versions
echo "= Docker info for ${DISTRO_NAME} start ="
docker info
echo "= Docker info for ${DISTRO_NAME} end ="
echo ""

DOCKER_CLI_VERSION=$(docker version --format '{{.Client.Version}}')
DOCKER_SERVER_VERSION=$(docker version --format '{{.Server.Version}}')
CONTAINERD_VERSION=$(docker version| awk '/containerd/{getline; print $2}')
RUNC_VERSION=$(docker version| awk '/runc/{getline; print $2}')
if [[ ${DISTRO_NAME} == "alpine" ]]; then
  echo "Skip version checks for ${DISTRO_NAME}"
else
  if [[ -z ${CONTAINERD_RUNC_TAG} ]]; then
    if [[ ! -d containerd ]]; then
      echo "= Cloning containerd ="
      git clone --depth 1 --branch ${CONTAINERD_TAG} https://github.com/containerd/containerd.git
    fi
    CONTAINERD_RUNC_TAG=$(< /workspace/containerd/script/setup/runc-version)
  fi
fi
if [[ ${RUNC_VERSION} != ${CONTAINERD_RUNC_TAG:1} ]]; then
  echo "ERROR: Version mismatch: RUNC version being tested is ${CONTAINERD_RUNC_TAG:1} and RUNC version downloaded from the Docker website is ${RUNC_VERSION}"
  exit 1
fi

if [[ ${DOCKER_CLI_VERSION:1} != ${DOCKER_TAG:1} ]]; then
  echo "ERROR: Version mismatch: Docker CLI version being tested is ${DOCKER_TAG:1} and Docker CLI version downloaded from the Docker website is ${DOCKER_CLI_VERSION:1}"
  exit 1
fi

if [[ ${DOCKER_SERVER_VERSION:1} != ${DOCKER_TAG:1} ]]; then
  echo "ERROR: Version mismatch: Docker Server version being tested is ${DOCKER_TAG:1} and Docker Server version downloaded from the Docker website is ${DOCKER_SERVER_VERSION:1}"
  exit 1

fi
if [[ ${CONTAINERD_VERSION} != ${CONTAINERD_TAG:1} ]]; then
  echo "ERROR: Version mismatch: containerd version being tested is ${CONTAINERD_TAG:1} and containerd version downloaded from the Docker website is ${CONTAINERD_VERSION}"
  exit 1
fi
# Run the docker test suite that consists of 3 tests
echo "= Docker test suite for ${DISTRO_NAME} ="
export GOPATH=${WORKSPACE}/test:/go
export PATH="/workspace/test/bin:$PATH"
export GO111MODULE=auto
cd /workspace/test/src/github.ibm.com/powercloud/dockertest
go install gotest.tools/gotestsum@v1.7.0

echo "* Go version:"
go version

if [[ ${DISTRO_NAME} == "alpine" ]]
then
  gotestsum --format standard-verbose --junitfile ${DIR_TEST}/junit-tests-${DISTRO_NAME}.xml --debug -- ./tests/${DISTRO_NAME}
else
  gotestsum --format standard-verbose --junitfile ${DIR_TEST}/junit-tests-${DISTRO_NAME}-${DISTRO_VERS}.xml --debug -- ./tests/${DISTRO_NAME}
fi

echo "== End of the docker test suite =="

exit 0
