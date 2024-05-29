pushd moby
mkdir tmp
touch tmp/out.txt
make -o TEST_SKIP_INTEGRATION_CLI=true build test-integration 2>&1 | tee tmp/out.txt
rc=$(grep "failure" tmp/out.txt | awk '{print $6;}')
popd
if [[ $rc == 0 ]]; then
  exit 0
fi
exit 1