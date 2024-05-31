pushd moby

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
    echo "$1 already created"
  fi
}

DIR_LOGS_COS="/mnt/s3_ppc64le-docker/prow-docker/ppc64le-ci/${COMMIT}"
checkDirectory ${DIR_LOGS_COS}

TEST_IGNORE_CGROUP_CHECK=true
TESTDEBUG="true"
rm -f ${DIR_LOGS_COS}/integration.log && touch ${DIR_LOGS_COS}/integration.log
echo "Integration test flags:"
echo "TEST_IGNORE_CGROUP_CHECK=${TEST_IGNORE_CGROUP_CHECK} TEST_DEBUG=${TEST_DEBUG}" > ${DIR_LOGS_COS}/integration.log
TEST_IGNORE_CGROUP_CHECK=${TEST_IGNORE_CGROUP_CHECK} TESTDEBUG=${TEST_DEBUG} make -o build test-integration 2>&1 | tee -a ${DIR_LOGS_COS}/integration.log

rc=$(grep "failure" ${DIR_LOGS_COS}/integration.log | awk '{print $6;}')
popd
if [[ $rc == 0 ]]; then
  exit 0
fi
exit 1