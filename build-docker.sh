#!/bin/bash
# Script building the dynamic docker packages

set -u

set -o allexport
source env.list
source "$(dirname "$0")/distro-vers-map.sh"

#If DOCKER_BUILD is set to 1, build Docker, otherwise don't
if [[ ${DOCKER_BUILD} == 0 ]]; then
  echo "DOCKER_BUILD is set to 0. Skipping building of docker packages."
  exit 0
fi
docker buildx create --name container --driver=docker-container default
NCPUs=`grep processor /proc/cpuinfo | wc -l`
echo "Nber of available CPUs: ${NCPUs}"

# Function to create the directory if it does not exist
checkDirectory() {
  if ! test -d $1
  then
    mkdir $1
    if [[ $? -ne 0 ]]; then
      exit 1
    fi
    echo "$1 created"
  else
    echo "$1 already created"
  fi
}

DIR_COS_BUCKET="/mnt/s3_ppc64le-docker/prow-docker/build-docker-${DOCKER_TAG}_${DATE}"
checkDirectory ${DIR_COS_BUCKET}

DIR_DOCKER="/workspace/docker-ce-${DOCKER_TAG}_${DATE}"
checkDirectory ${DIR_DOCKER}

DIR_DOCKER_COS="${DIR_COS_BUCKET}/docker-ce-${DOCKER_TAG}"
checkDirectory ${DIR_DOCKER_COS}

DIR_LOGS="/workspace/logs"
checkDirectory ${DIR_LOGS}

DIR_LOGS_COS="${DIR_COS_BUCKET}/logs"
checkDirectory ${DIR_LOGS_COS}

STATIC_LOG="static.log"

# Count of distros
nb=$((`echo $DEBS | wc -w`+`echo $RPMS | wc -w`))

# Function to build docker packages
# $1 : distro
buildDocker() {
  echo "= Building docker for $1 ="
  local build_before=$SECONDS
  local DISTRO=$1
  local DISTRO_NAME="$(cut -d'-' -f1 <<<"${DISTRO}")"
  local DISTRO_VERS="$(cut -d'-' -f2 <<<"${DISTRO}")"
  local DISTRO_VERS_NAME
  DISTRO_VERS_NAME="$(distro_vers_to_name "${DISTRO_VERS}")"
  cd /workspace/packaging && PKG_REF="docker-${DOCKER_TAG}" LOCAL_PLATFORM="linux/ppc64le" docker buildx bake pkg-docker-engine-"${DISTRO_NAME}""${DISTRO_VERS}" --builder="container"
  PKG_REF="${COMPOSE_TAG}" LOCAL_PLATFORM="linux/ppc64le" docker buildx bake pkg-compose-"${DISTRO_NAME}""${DISTRO_VERS}" --builder="container"
  PKG_REF="${BUILDX_TAG}" LOCAL_PLATFORM="linux/ppc64le" docker buildx bake pkg-buildx-"${DISTRO_NAME}""${DISTRO_VERS}" --builder="container"

  # Source directories produced by docker buildx bake
  local PKG_BASE="/workspace/packaging/bin/pkg"
  local ENGINE_SRC="${PKG_BASE}/docker-engine/${DISTRO_NAME}${DISTRO_VERS}/linux_ppc64le/${DISTRO_NAME}/${DISTRO_VERS_NAME}/ppc64le"
  local COMPOSE_SRC="${PKG_BASE}/compose/${DISTRO_NAME}${DISTRO_VERS}/linux_ppc64le/${DISTRO_NAME}/${DISTRO_VERS_NAME}/ppc64le"
  local BUILDX_SRC="${PKG_BASE}/buildx/${DISTRO_NAME}${DISTRO_VERS}/linux_ppc64le/${DISTRO_NAME}/${DISTRO_VERS_NAME}/ppc64le"

  # Destination inside the archive: bundles/<DOCKER_TAG>/build-deb/<DISTRO_NAME>-<DISTRO_VERS_NAME>
  local ARCHIVE_INNER="bundles/${DOCKER_TAG}/build-deb/${DISTRO_NAME}-${DISTRO_VERS_NAME}"

  # Staging directory for archive assembly
  local STAGE_DIR
  STAGE_DIR="$(mktemp -d)"
  mkdir -p "${STAGE_DIR}/${ARCHIVE_INNER}"

  # Collect docker-engine packages (glob on package name to be resilient to version mismatches)
  cp "${ENGINE_SRC}/docker-ce-rootless-extras_"*"_ppc64el.deb"     "${STAGE_DIR}/${ARCHIVE_INNER}/"
  cp "${ENGINE_SRC}/docker-ce_"*"_ppc64el.changes"                 "${STAGE_DIR}/${ARCHIVE_INNER}/"
  cp "${ENGINE_SRC}/docker-ce_"*"_ppc64el.buildinfo"               "${STAGE_DIR}/${ARCHIVE_INNER}/"
  cp "${ENGINE_SRC}/docker-ce_"*"_ppc64el.deb"                     "${STAGE_DIR}/${ARCHIVE_INNER}/"

  # Collect compose package (glob on package name to be resilient to version mismatches)
  cp "${COMPOSE_SRC}/docker-compose-plugin_"*"_ppc64el.deb"        "${STAGE_DIR}/${ARCHIVE_INNER}/"

  # Collect buildx package (glob on package name to be resilient to version mismatches)
  cp "${BUILDX_SRC}/"*"_ppc64el."*                                  "${STAGE_DIR}/${ARCHIVE_INNER}/"

  # Create archive and place it where the downstream check expects it
  # Archive name uses the codename (e.g. debian-bookworm) not the numeric version (e.g. debian-12)
  local DISTRO_NAMED="${DISTRO_NAME}-${DISTRO_VERS_NAME}"
  mkdir -p /workspace/packaging/build
  tar -czf "/workspace/packaging/build/bundles-ce-${DISTRO_NAMED}-ppc64le.tar.gz" \
      -C "${STAGE_DIR}" bundles

  rm -rf "${STAGE_DIR}"

  # Check if the dynamic docker package has been built
  if test -f /workspace/packaging/build/bundles-ce-${DISTRO_NAMED}-ppc64le.tar.gz
  then
    echo "Docker for ${DISTRO_NAMED} built"

    echo "== Copying dynamic docker package bundles-ce-${DISTRO_NAMED}-ppc64le.tar.gz to ${DIR_DOCKER} =="
    cp -r /workspace/packaging/build/bundles-ce-${DISTRO_NAMED}-ppc64le.tar.gz ${DIR_DOCKER}

    echo "== Copying dynamic docker package bundles-ce-${DISTRO_NAMED}-ppc64le.tar.gz to ${DIR_DOCKER_COS} =="
    cp -r /workspace/packaging/build/bundles-ce-${DISTRO_NAMED}-ppc64le.tar.gz ${DIR_DOCKER_COS}

    echo "== Copying log to ${DIR_LOGS_COS} =="
    cp ${DIR_LOGS}/build_docker_${DISTRO}.log ${DIR_LOGS_COS}/build_docker_${DISTRO}.log

    # Checking everything has been copied
    if test -f ${DIR_DOCKER}/bundles-ce-${DISTRO_NAMED}-ppc64le.tar.gz && test -f ${DIR_DOCKER_COS}/bundles-ce-${DISTRO_NAMED}-ppc64le.tar.gz && test -f ${DIR_LOGS_COS}/build_docker_${DISTRO}.log
    then
      echo "Docker for ${DISTRO_NAMED} was copied."
    else
      echo "Docker for ${DISTRO_NAMED} was not copied."
    fi
  else
    echo "ERROR: Docker for ${DISTRO_NAMED} not built"

    echo "== Copying log to ${DIR_LOGS_COS} =="
    cp ${DIR_LOGS}/build_docker_${DISTRO}.log ${DIR_LOGS_COS}/build_docker_${DISTRO}.log

    echo "== Log start for the build failure of ${DISTRO_NAMED} =="
    cat ${DIR_LOGS}/build_docker_${DISTRO}.log
    echo "== Log end for the build failure of ${DISTRO_NAMED} =="

  fi

  local build_after=$SECONDS
  local build_duration=$(expr $build_after - $build_before) && echo "DURATION BUILD docker ${DISTRO} : $(($build_duration / 60)) minutes and $(($build_duration % 60)) seconds elapsed."
}

echo "# Building dynamic docker packages #"

before=$SECONDS
# 1) Build the list of distros
# List of Distros that appear in the list though they are EOL or must not be built
DisNo+=( "debian-bullseye" )
for PACKTYPE in DEBS RPMS
do
  for DISTRO in ${!PACKTYPE}
  do
    No=0
    for (( d=0 ; d<${#DisNo[@]} ; d++ ))
    do
      if [ ${DISTRO} == ${DisNo[d]} ]
      then
        No=1
        break
      fi
    done
    if [ $No -eq 0 ]
    then
      echo "Distro / Packtype: ${DISTRO} / ${PACKTYPE}"
      Dis+=( $DISTRO )
      Pac+=( $PACKTYPE )
    fi
  done
done
nD=${#Dis[@]}
echo "Number of distros: $nD"

# 2) Launch builds and wait for them in parallel
# Max number of builds running in parallel:
#  (it looks like using all CPUs is too hard. Use half)
let "max=NCPUs/2"
echo "Max number of builds running in parallel: ${max}"
# Current number of builds being run:
n=0
# Index of Distro & Build in the pids[] Dis[] and Pac[] arrays:
i=0
while true
do
  while [ $n -lt $max ] && [ $i -lt ${nD} ]
  do
    buildDocker ${Dis[i]} &
    pids+=( $! )
    echo "Build distrib: i:$i ${Dis[i]} pid:${pids[i]}"
    let "n=n+1"
    let "i=i+1"
#    echo "i: $i  n: $n"
  done
#  echo "PIDs: ${pids[*]}"
  for (( j=0 ; j<${#pids[@]} ; j++ ))
  do
    pid=${pids[j]}
    if [ ${pid} -ne 0 ]
    then
      break
    fi
  done
  echo "Waiting for '${pid}' '${Dis[j]}' build to complete"
  wait ${pid}
  echo "            '${pid}' '${Dis[j]}' build completed"
  pids[j]=0
  let "n=n-1"
#  echo "i: $i  n: $n" 
  if [ $n -eq 0 ]
  then
    break
  fi
done
after=$SECONDS
duration=$(expr $after - $before) && echo "DURATION TOTAL DOCKER : $(($duration / 60)) minutes and $(($duration % 60)) seconds elapsed."

cd /workspace
echo "= Building static binaries ="

before_build=$SECONDS

cd /workspace/docker-ce-packaging/static

CONT_NAME=docker-build-static
# https://quay.io/repository/powercloud/docker-ce-build?tab=tags
QUAYIO_REPOSITORY="powercloud"
# Test ! Test a new DockerInDocker image before pushing it to Raji's Production Cluster
# https://quay.io/repository/trex58i/docker-ce-build?tab=tags
#QUAYIO_REPOSITORY="trex58i"
if [[ ! -z ${DOCKER_SECRET_AUTH+z} ]]
then
  DOCKER_SECRET_AUTH_IN_ENV="--env DOCKER_SECRET_AUTH"
else
  DOCKER_SECRET_AUTH_IN_ENV=""
fi
echo "More trace for debugging static build issue: get full command line for running:"
echo "    docker run [options] -ti quay.io/powercloud/docker-ce-build /bin/bash"
echo "on fyre:focal1 ."
echo "docker run -d \
           -v /workspace:/workspace \
           -v ${PATH_SCRIPTS}:${PATH_SCRIPTS} \
           -v ${ARTIFACTS}:${ARTIFACTS} \
           --env PATH_SCRIPTS \
           ${DOCKER_SECRET_AUTH_IN_ENV} \
           --privileged \
           --name ${CONT_NAME} \
           quay.io/${QUAYIO_REPOSITORY}/docker-ce-build@${DIND_IMG_STATIC_HASH} \
           ${PATH_SCRIPTS}/build-static.sh"
           
docker run -d \
           -v /workspace:/workspace \
           -v ${PATH_SCRIPTS}:${PATH_SCRIPTS} \
           -v ${ARTIFACTS}:${ARTIFACTS} \
           --env PATH_SCRIPTS \
           ${DOCKER_SECRET_AUTH_IN_ENV} \
           --privileged \
           --name ${CONT_NAME} \
           quay.io/${QUAYIO_REPOSITORY}/docker-ce-build@${DIND_IMG_STATIC_HASH} \
           ${PATH_SCRIPTS}/build-static.sh

status_code="$(docker container wait ${CONT_NAME})"
if [[ ${status_code} -ne 0 ]]; then
  # Save static build logs
  echo "==== Copying static log to ${DIR_LOGS_COS}/${STATIC_LOG} ===="
  cp ${DIR_LOGS}/${STATIC_LOG} ${DIR_LOGS_COS}/${STATIC_LOG}
  
  # Note: Messages from build-static.sh and build-docker.sh are not always echoed by "docker logs" in temporal order
  echo "The static binaries build failed. See details from '${STATIC_LOG}'"
  docker logs ${CONT_NAME}
else
  after_build=$SECONDS
  duration_build=$(expr $after_build - $before_build)
  echo "DURATION BUILD STATIC : $(($duration_build / 60)) minutes and $(($duration_build % 60)) seconds elapsed."
  docker logs ${CONT_NAME}

  # Check if the static packages have been built
  if test -f build/linux/tmp/docker-ppc64le.tgz
  then
    echo "Static binaries built"

    echo "== Copying static packages to ${DIR_DOCKER} =="
    cp build/linux/tmp/*.tgz ${DIR_DOCKER}

    echo "=== Copying static packages to ${DIR_DOCKER_COS} ==="
    cp build/linux/tmp/*.tgz ${DIR_DOCKER_COS}

    echo "==== Copying static log to ${DIR_LOGS_COS}/${STATIC_LOG} ===="
    cp ${DIR_LOGS}/${STATIC_LOG} ${DIR_LOGS_COS}/${STATIC_LOG}

    # Checking everything has been copied
    ls -f ${DIR_DOCKER}/*.tgz && ls -f ${DIR_DOCKER_COS}/*.tgz && ls -f ${DIR_LOGS_COS}/${STATIC_LOG}
    if [[ $? -eq 0 ]]
    then
      echo "The static binaries were copied."
    else
      echo "The static binaries were not copied."
    fi
  fi
fi

cd /workspace

# Check if the docker-ce packages have been built
ls ${DIR_DOCKER}/*
if [[ $? -ne 0 ]]
then
  # No docker-ce packages built
  echo "No packages built for docker in ${DIR_DOCKER}"
  exit 1
else
  # Docker-ce packages built
  echo "Docker packages built"
  exit 0
fi
