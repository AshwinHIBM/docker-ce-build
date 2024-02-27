pushd moby
make -o build test-unit
cp bundles/junit-report.xml ${ARTIFACTS}
popd