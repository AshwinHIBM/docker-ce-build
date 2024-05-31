pushd moby

# Store logs by date to avoid overwriting
DATE=`date +%d%m%y-%H%M`
export DATE=${DATE}

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

DIR_LOGS_COS="/mnt/s3_ppc64le-docker/prow-docker/ppc64le-ci/${DATE}"
checkDirectory ${DIR_LOGS_COS}

make -o build test-unit 2>&1 | tee ${DIR_LOGS_COS}/unit.log
rc=$(grep "failure" ${DIR_LOGS_COS}/unit.log | awk '{print $6;}')
cp bundles/junit-report.xml ${ARTIFACTS}
popd

if [[ $rc == 0 ]]; then
  exit 0
fi
exit 1