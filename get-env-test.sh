#!/bin/bash
# Script to get the clone containerd if RUNC_VERSION is unspecified

set -o allexport
source /workspace/${FILE_ENV}
echo "----Present working directory-----"
pwd
if [[ -z ${CONTAINERD_RUNC_TAG} ]]; then    
    git clone --depth 1 --branch ${CONTAINERD_TAG} https://github.com/containerd/containerd.git
fi