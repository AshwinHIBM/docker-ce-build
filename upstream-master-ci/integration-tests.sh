pushd moby
mkdir tmp
touch tmp/out.txt
TEST_IGNORE_CGROUP_CHECK=true TESTDEBUG="true" TEST_SKIP_INTEGRATION_CLI=true make -o build test-integration 2>&1 | tee tmp/out.txt
rc=$(grep "failure" tmp/out.txt | awk '{print $6;}')
popd
if [[ $rc == 0 ]]; then
  exit 0
fi
exit 1