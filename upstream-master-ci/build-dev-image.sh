pushd ${PWD}/moby

# Store logs by commit id to avoid overwriting
export COMMIT=$(git rev-parse --short HEAD)

checkDirectory() {
  if ! test -d $1
  then
    mkdir $1
    if [[ $? -ne 0 ]]; then
      exit 1
    fi
    echo "$1 created"
  else
    echo "$1 already exists, will not create again."
  fi
}

DIR_LOGS_COS="/mnt/s3_ppc64le-docker/prow-docker/ppc64le-ci/${COMMIT}"
checkDirectory ${DIR_LOGS_COS}

rm -f ${DIR_LOGS_COS}/build-dev-image.log && touch ${DIR_LOGS_COS}/build-dev-image.log
docker buildx build --load --force-rm -t "docker-dev" . 2>&1 | tee -a "${DIR_LOGS_COS}/build-dev-image.log"

popd
exit 0