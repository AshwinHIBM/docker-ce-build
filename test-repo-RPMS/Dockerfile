# Dockerfile to run the staging tests

ARG DISTRO_NAME
ARG DISTRO_VERS
ARG REPO_HOSTNAME=download.docker.com

FROM public.ecr.aws/docker/library/$DISTRO_NAME:$DISTRO_VERS

ARG DISTRO_NAME
ARG DISTRO_VERS
ARG REPO_HOSTNAME

WORKDIR /workspace
RUN mkdir -p /workspace
ENV WORKSPACE=/workspace \
    TERM=xterm
ENV PATH /usr/local/go/bin:$PATH
ARG TINI_VERSION=v0.19.0
RUN yum install -y dnf-plugins-core || :; \
    yum config-manager --set-enabled crb || :; \
    yum config-manager --set-enabled powertools || :; \
    yum config-manager --set-enabled PowerTools || :

RUN set -eux; yum -y install make gcc git glibc-static cmake findutils procps-ng && \
    yum -y clean all

RUN set -eux; yum install -y yum-utils &&\
	yum-config-manager --add-repo https://${REPO_HOSTNAME}/linux/${DISTRO_NAME}/docker-ce-staging.repo &&\
	yum -y install docker-ce docker-ce-cli containerd.io

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

# Commit pointing to the latest Docker-in-Docker script as of September, 2025.
# https://github.com/moby/moby/tree/master/hack/dind
ARG DIND_COMMIT=8d9e3502aba39127e4d12196dae16d306f76993d
# Commit pointing to the latest stable Dockerd-entrypoint script as of September, 2025.
# https://github.com/docker-library/docker/tree/master/28/dind
ARG DOCKERD_COMMIT=52c8bfa9869c9c5605c6c03dc9a82cfe426ace77
ARG TINI_VERSION=v0.19.0

COPY test-launch.sh /usr/local/bin/test-launch.sh

RUN set -eux; \
        curl "https://raw.githubusercontent.com/moby/moby/${DIND_COMMIT}/hack/dind" -o /usr/local/bin/dind; \
        curl "https://raw.githubusercontent.com/docker-library/docker/${DOCKERD_COMMIT}/28/dind/dockerd-entrypoint.sh" -o /usr/local/bin/dockerd-entrypoint.sh; \
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

ARG GO_VERSION=1.25.0

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
