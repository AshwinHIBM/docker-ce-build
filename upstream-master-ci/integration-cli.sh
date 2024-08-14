pushd cli

export COMMIT=$(git rev-parse --short HEAD)
DIR_LOGS_COS="/mnt/s3_ppc64le-docker/prow-docker/ppc64le-ci/integration-cli"
rm -f ${DIR_LOGS_COS}/${COMMIT}.log && touch ${DIR_LOGS_COS}/${COMMIT}.log

# The below two replacements are made because notary is not released 
# for ppc64le
sed -i 's/ARG NOTARY_VERSION=v0.6.1/RUN go install -tags pkcs11 github.com\/theupdateframework\/notary\/cmd\/notary@latest/g' Dockerfile
sed -i 's/ADD --chmod=0755 https:\/\/github.com\/theupdateframework\/notary\/releases\/download\/${NOTARY_VERSION}\/notary-Linux-amd64 \/usr\/local\/bin\/notary/RUN mv ${GOPATH}\/bin\/notary \/usr\/local\/bin\/notary/g' Dockerfile

# The below replacements are needed because the 'Docker' image is
# not supported on ppc64le hence we maintain our own.
sed -i "s/docker:.*/quay.io\/powercloud\/docker-ce-build@sha256:b00a990424d9bb4d3d4bf76f64ee2cf31992d1a9364e8cbf33c371380efeebe3'/g" ./e2e/compose-env.yaml
sed -i "/insecure-registry/d" ./e2e/compose-env.yaml
TEST_DEBUG="true"
echo "Integration CLI test flags:"
echo "TEST_DEBUG=${TEST_DEBUG}" > ${DIR_LOGS_COS}/${COMMIT}.log
set -o pipefail
make -f docker.Makefile TEST_DEBUG="true" test-e2e-non-experimental 2>&1 | tee ${DIR_LOGS_COS}/${COMMIT}.log
rc=$?
echo "The exit code is ${rc}"
popd
exit ${rc}
grep "failure" ${DIR_LOGS_COS}/${COMMIT}.log > /dev/null 2>&1
if [[ $? == 1 ]]; then
  popd
  exit 0
fi
popd
exit 1