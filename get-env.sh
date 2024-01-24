#!/bin/bash
# Script to get the env.list file and to generate the list of distros
# The env.list would contain the DOCKER_TAG, the DOCKER_CLI hash, the DOCKER_ENGINE hash, the DOCKER_PACKAGING_HASH, which is the commit associated to the version of docker,
# CONTAINERD_BUILD, which is set to 1 if there has been a new version of containerd released,
# CONTAINERD_TAG, CONTAINERD_PACKAGING_HASH which is the commit associated to the version of containerd,
# and RUNC_VERS, containing the version of runc used to build the static packages.

set -eu

PATH_COS="/mnt"
PATH_PASSWORD="/root/.s3fs_cos_secret"

COS_BUCKET_PRIVATE="ppc64le-docker"
URL_COS_PRIVATE="https://s3.us-south.cloud-object-storage.appdomain.cloud"

FILE_ENV_PATH="${PATH_SCRIPTS}/env"
FILE_ENV="env.list"
DISABLE_DISTRO_DISCOVERY=0

# Mount the COS bucket if not mounted
if ! test -d ${PATH_COS}/s3_${COS_BUCKET_PRIVATE}
then
    # Set up the s3 secret if not already configured
    if ! test -f ${PATH_PASSWORD}
    then
        echo ":${S3_SECRET_AUTH}" > ${PATH_PASSWORD}
        chmod 600 ${PATH_PASSWORD}
    fi
    mkdir -p ${PATH_COS}/s3_${COS_BUCKET_PRIVATE}
    s3fs ${COS_BUCKET_PRIVATE} ${PATH_COS}/s3_${COS_BUCKET_PRIVATE} -o url=${URL_COS_PRIVATE} -o passwd_file=${PATH_PASSWORD} -o ibm_iam_auth
fi

# Copy the env.list to the local /workspace
cp ${FILE_ENV_PATH}/${FILE_ENV} /workspace/${FILE_ENV}

set -o allexport
source /workspace/${FILE_ENV}

# Generate the list of distributions and populate docker-ce-packaging from git
mkdir docker-ce-packaging
pushd docker-ce-packaging
git init
git remote add origin https://github.com/docker/docker-ce-packaging.git
git fetch origin ${DOCKER_PACKAGING_HASH}
git checkout FETCH_HEAD

make REF=${DOCKER_TAG} DOCKER_ENGINE_HASH=${DOCKER_ENGINE_HASH} DOCKER_CLI_HASH=${DOCKER_CLI_HASH} checkout
popd


if [[ ${DISABLE_DISTRO_DISCOVERY} != "1" ]]
then
    echo "Discovering distribution list from git"
    # Get the distributions list in the docker-ce-packaging repository
    echo DEBS=\"`cd docker-ce-packaging/deb && ls -1d debian-* ubuntu-*`\" >> ${FILE_ENV}
    echo RPMS=\"`cd docker-ce-packaging/rpm && ls -1d centos-* fedora-*`\" >> ${FILE_ENV}
    source /workspace/${FILE_ENV}
else
    echo "Disable distribution discovery from git"
fi

echo "- Using DEBS='$DEBS'"
echo "- Using RPMS='$RPMS'"



# Check if we have the env.list
if ! test -f /workspace/${FILE_ENV}
then
    echo "The env.list has not been generated."
    exit 1
else
# Check there are 9 env variables in env.list from github
    if grep -Fq "DOCKER_TAG" ${FILE_ENV} && grep -Fq "DOCKER_CLI_HASH" && grep -Fq "DOCKER_ENGINE_HASH" ${FILE_ENV} && grep -Fq "DOCKER_PACKAGING_HASH" ${FILE_ENV} && grep -Fq "CONTAINERD_BUILD" ${FILE_ENV} && grep -Fq "CONTAINERD_HASH" ${FILE_ENV} && grep -Fq "CONTAINERD_TAG" ${FILE_ENV} && grep -Fq "CONTAINERD_PACKAGING_HASH" ${FILE_ENV} && grep -Fq "RUNC_VERS" ${FILE_ENV} && grep -Fq "STATIC_HASH" ${FILE_ENV}
    then
        echo "DOCKER_TAG : ${DOCKER_TAG}, DOCKER_CLI_HASH : ${DOCKER_CLI_HASH}, DOCKER_ENGINE_HASH : ${DOCKER_ENGINE_HASH}, DOCKER_PACKAGING_HASH : ${DOCKER_PACKAGING_HASH}, CONTAINERD_BUILD : ${CONTAINERD_BUILD}, CONTAINERD_HASH : ${CONTAINERD_HASH}, CONTAINERD_TAG : ${CONTAINERD_TAG}, CONTAINERD_PACKAGING_HASH : ${CONTAINERD_PACKAGING_HASH}, RUNC_VERS :${RUNC_VERS} and ${STATIC_HASH} are in env.list."
    else
        echo "DOCKER_TAG, DOCKER_CLI_HASH, DOCKER_ENGINE_HASH, DOCKER_PACKAGING_HASH, CONTAINERD_BUILD, CONTAINERD_HASH, CONTAINERD_TAG, CONTAINERD_PACKAGING_HASH, RUNC_VERS and/or STATIC_HASH are not in env.list."
        cat /workspace/${FILE_ENV}
        exit 1
    fi
# check there are two env variables in env.list we just added regarding the distributions
    if grep -Fq "DEBS" ${FILE_ENV} || grep -Fq "RPMS" ${FILE_ENV}
    then
        echo "DEBS and/or RPMS are in env.list."
    else
        echo "DEBS and RPMS are not in env.list."
        cat /workspace/${FILE_ENV}
        exit 1
    fi
    echo "The env.list has been copied and the list of distributions has been generated and added to env.list."
fi
