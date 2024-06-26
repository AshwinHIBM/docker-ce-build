pushd cli
mkdir tmp
touch tmp/out.txt
make -f docker.Makefile test-e2e-non-experimental 2>&1 | tee tmp/out.txt
rc=$(grep "failure" tmp/out.txt | awk '{print $6;}')
popd
if [[ $rc == 0 ]]; then
  exit 0
fi
exit 1