# Dockerfile to test RPMS packages

ARG DISTRO_NAME
ARG DISTRO_VERS

FROM ppc64le/$DISTRO_NAME:$DISTRO_VERS

ARG DISTRO_NAME
ARG DISTRO_VERS

WORKDIR /workspace
RUN mkdir -p /workspace
ARG TINI_VERSION=v0.19.0
ENV WORKSPACE=/workspace \
    TERM=xterm
ENV PATH /usr/local/go/bin:$PATH
RUN yum install -y dnf-plugins-core || :; \
    yum config-manager --set-enabled crb || :; \
    yum config-manager --set-enabled powertools || :; \
    yum config-manager --set-enabled PowerTools || :

RUN set -eux; yum -y install cmake git make gcc glibc-static findutils procps-ng

COPY bundles-*.tar.gz /workspace
COPY *.rpm /workspace/
COPY test-launch.sh /usr/local/bin/test-launch.sh

RUN set -eux; \
    tar -xvzf bundles-*.tar.gz --wildcards  --strip-components 6 '*/RPMS/*' &&\
    yum -y *.rpm && \
    yum -y clean all

##
#Docker in Docker inspired from
#  https://github.com/docker-library/docker/tree/master/20.10/dind
# set up subuid/subgid so that "--userns-remap=default" works out-of-the-box
##
RUN set -eux; \
	groupadd --system dockremap; \
	adduser --system -g dockremap dockremap; \
	echo 'dockremap:165536:65536' >> /etc/subuid; \
	echo 'dockremap:165536:65536' >> /etc/subgid

# Commit pointing to the latest Docker-in-Docker script as of January, 2024.
# https://github.com/moby/moby/tree/master/hack/dind
ARG DIND_COMMIT=65cfcc28ab37cb75e1560e4b4738719c07c6618e
# Commit pointing to the latest stable Dockerd-entrypoint script as of January, 2024.
# https://github.com/docker-library/docker/tree/master/25/dind
ARG DOCKERD_COMMIT=b317cabfb873fef32ac8cad0cd58d6e6c32a63a4

RUN set -eux; \
        curl "https://raw.githubusercontent.com/moby/moby/${DIND_COMMIT}/hack/dind" -o /usr/local/bin/dind; \
        curl "https://raw.githubusercontent.com/docker-library/docker/${DOCKERD_COMMIT}/27/dind/dockerd-entrypoint.sh" -o /usr/local/bin/dockerd-entrypoint.sh; \
        chmod +x /usr/local/bin/dind; \
        chmod +x /usr/local/bin/dockerd-entrypoint.sh; \
        git clone https://github.com/krallin/tini.git "/workspace/tini"; \
        pushd ./tini; \
        git checkout -q "$TINI_VERSION"; \
        cmake .; \
        make tini-static; \
        cp tini-static "/usr/local/bin/docker-init"; \
        popd; \
        chmod +x /usr/local/bin/test-launch.sh;

ARG GO_VERSION=1.22.5

RUN set -eux; \
    url="https://dl.google.com/go/${GO_VERSION}";\
    curl "$url" -o go.tgz --progress-bar; \
    tar -C /usr/local -xzf go.tgz; \
    rm go.tgz; \
    go version;

VOLUME /var/lib/docker
EXPOSE 2375 2376

ENTRYPOINT ["/usr/local/bin/test-launch.sh"]
CMD []
