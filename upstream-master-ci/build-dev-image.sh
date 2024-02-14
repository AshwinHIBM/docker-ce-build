pushd ${PWD}/moby
docker buildx build --load --force-rm -t "docker-dev" .
popd
exit 0