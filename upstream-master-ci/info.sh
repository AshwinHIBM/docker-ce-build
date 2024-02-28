docker version
docker info
curl -fsSL -o ${PWD}/check-config.sh "https://raw.githubusercontent.com/moby/moby/master/contrib/check-config.sh"
bash ${PWD}/check-config.sh
exit $?