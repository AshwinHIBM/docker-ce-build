#pushd moby
#make -o build test-unit
#cp bundles/junit-report.xml ${ARTIFACTS}
rc=$(echo "DONE 3256 tests, 27 skipped, 10 failures in 129.686s" | grep "failures" | awk '{print $6;}')
if [[ $rc == 0 ]]; then
  echo "No failures"
  exit 0
fi
echo "$rc failures"
exit $rc
#popd