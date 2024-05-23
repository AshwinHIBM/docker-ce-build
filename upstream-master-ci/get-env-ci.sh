set -o allexport
# Clone the moby repository
git clone https://github.com/moby/moby.git
sed -i 's@export TEST_CLIENT_BINARY=/usr/local/cli/$(basename "$DOCKER_CLI_PATH")@TEST_CLIENT_BINARY=/usr/local/bin/dockerd@g' moby/hack/make/.integration-daemon-start
sed -i '73i wget -o /usr/local/bin/dockerd-entrypoint.sh https://raw.githubusercontent.com/docker-library/docker/master/26/dind/dockerd-entrypoint.sh' moby/hack/make/.integration-daemon-start
sed -i '74i git clone https://github.com/ppc64le-cloud/docker-ce-build.git' moby/hack/make/.integration-daemon-start
sed -i '75i pushd docker-ce-build && dockerctl.sh start && popd' moby/hack/make/.integration-daemon-start