# Store logs by commit id to avoid overwriting
pushd ${PWD}/moby
export COMMIT=$(git rev-parse --short HEAD)
popd

checkDirectory() {
  if ! test -d $1
  then
    echo "Could not create $1, exiting."
    mkdir $1
    if [[ $? -ne 0 ]]; then
      exit 1
    fi
    echo "$1 created"
  else
    echo "$1 already created"
  fi
}

DIR_LOGS_COS="/mnt/s3_ppc64le-docker/prow-docker/ppc64le-ci/${COMMIT}"
checkDirectory ${DIR_LOGS_COS}

rm -f ${DIR_LOGS_COS}/info.log && touch ${DIR_LOGS_COS}/info.log
docker version 2>&1 | tee -a "${DIR_LOGS_COS}/info.log"
docker info 2>&1 | tee -a "${DIR_LOGS_COS}/info.log"
curl -fsSL -o ${PWD}/check-config.sh "https://raw.githubusercontent.com/moby/moby/master/contrib/check-config.sh" 2>&1 | tee -a "${DIR_LOGS_COS}/info.log"
set -o pipefail
bash ${PWD}/check-config.sh 2>&1 | tee -a "${DIR_LOGS_COS}/info.log" || true
exit $?