# Dockerfile to run the staging tests

ARG GOLANG_VERSION=1.21.9
ARG DISTRO_NAME
ARG DISTRO_VERS
ARG REPO_HOSTNAME=download-stage.docker.com

FROM ppc64le/ubuntu:mantic

ARG GOLANG_VERSION
ARG DISTRO_NAME
ARG DISTRO_VERS
ARG REPO_HOSTNAME

WORKDIR /workspace
RUN mkdir -p /workspace
ENV WORKSPACE=/workspace \
    TERM=xterm
ENV PATH /usr/local/go/bin:$PATH

RUN apt-get -y update && apt-get -y upgrade && DEBIAN_FRONTEND="noninteractive" apt-get install -y tzdata; \
    apt-get update && apt-get install -y --no-install-recommends \
    apt-transport-https \
    ca-certificates \
    cmake \
    curl \
    dbus-user-session \
    git \
    gnupg2 \
    software-properties-common \
    lsb-release\
    make\
    gcc\
    libc-dev\
    procps\
    tini \
    iptables libdevmapper1.02.1 && \
    rm -rf /var/lib/apt/lists/* && \
    apt-get -y clean

#Install from Docker-ce staging
RUN set -eux; curl -fsSL https://${REPO_HOSTNAME}/linux/${DISTRO_NAME}/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg &&\
    echo "deb [arch=ppc64el signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://${REPO_HOSTNAME}/linux/${DISTRO_NAME} ${DISTRO_VERS} stable"\
    | tee /etc/apt/sources.list.d/docker.list > /dev/null  &&\
    apt-get update && apt-get -y install docker-ce docker-ce-cli containerd.io

##
#Docker in Docker inspired from
#  https://github.com/docker-library/docker/tree/master/20.10/dind
# set up subuid/subgid so that "--userns-remap=default" works out-of-the-box
##
RUN set -eux; \
        addgroup --system dockremap; \
        adduser --system --ingroup dockremap dockremap; \
        echo 'dockremap:165536:65536' >> /etc/subuid; \
        echo 'dockremap:165536:65536' >> /etc/subgid

COPY test-launch.sh /usr/local/bin/test-launch.sh

# Commit pointing to the latest Docker-in-Docker script as of January, 2024.
# https://github.com/moby/moby/tree/master/hack/dind
ARG DIND_COMMIT=65cfcc28ab37cb75e1560e4b4738719c07c6618e
# Commit pointing to the latest stable Dockerd-entrypoint script as of January, 2024.
# https://github.com/docker-library/docker/tree/master/25/dind
ARG DOCKERD_COMMIT=d3e33ac3bc1eab5d436b7ab2981ba539ebbb7275

RUN set -eux; \
        curl "https://raw.githubusercontent.com/moby/moby/${DIND_COMMIT}/hack/dind" -o /usr/local/bin/dind; \
        curl "https://raw.githubusercontent.com/docker-library/docker/${DOCKERD_COMMIT}/25/dind/dockerd-entrypoint.sh" -o /usr/local/bin/dockerd-entrypoint.sh; \
        chmod +x /usr/local/bin/dind; \
        chmod +x /usr/local/bin/dockerd-entrypoint.sh; \
        cp $(which tini) "/usr/local/bin/docker-init"; \
        chmod +x /usr/local/bin/test-launch.sh;

RUN set -eux; \
    url="https://storage.googleapis.com/golang/go${GOLANG_VERSION}.linux-ppc64le.tar.gz";\
    curl "$url" -o go.tgz --progress-bar; \
    tar -C /usr/local -xzf go.tgz; \
    rm go.tgz; \
    go version;


VOLUME /var/lib/docker
EXPOSE 2375 2376

ENTRYPOINT ["/usr/local/bin/test-launch.sh"]
CMD []
