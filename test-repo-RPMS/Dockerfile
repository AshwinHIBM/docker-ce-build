# Dockerfile to run the staging tests

ARG GOLANG_VERSION=1.19.9
ARG DISTRO_NAME
ARG DISTRO_VERS
ARG REPO_HOSTNAME=download-stage.docker.com

FROM ppc64le/$DISTRO_NAME:$DISTRO_VERS

ARG GOLANG_VERSION
ARG DISTRO_NAME
ARG DISTRO_VERS
ARG REPO_HOSTNAME

WORKDIR /workspace
RUN mkdir -p /workspace
ENV WORKSPACE=/workspace \
    TERM=xterm
ENV PATH /usr/local/go/bin:$PATH
ENV TINI_VERSION=v0.19.0
RUN yum install -y dnf-plugins-core || :; \
    yum config-manager --set-enabled crb || :; \
    yum config-manager --set-enabled powertools || :; \
    yum config-manager --set-enabled PowerTools || :; \ 
    set -eux; yum -y install make gcc git glibc-static cmake findutils procps-ng; \
    set -eux; yum install -y yum-utils\
	&& yum-config-manager --add-repo https://${REPO_HOSTNAME}/linux/${DISTRO_NAME}/docker-ce-staging.repo\
	&& yum -y install docker-ce docker-ce-cli containerd.io ;\
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

# Commit pointing to the latest Docker-in-Docker script as of May 16, 2023.
# https://github.com/moby/moby/tree/master/hack/dind
ENV DIND_COMMIT 1f32e3c95d72a29b3eaacba156ed675dba976cb5
# Commit pointing to the latest stable Dockerd-entrypoint script as of May 16, 2023.
# https://github.com/docker-library/docker/tree/master/23.0/dind
ENV DOCKERD_COMMIT a3ca225e9c0e568cf87a7b60c951b939c3964c91
ENV TINI_VERSION:=v0.19.0

COPY test-launch.sh /usr/local/bin/test-launch.sh

RUN set -eux; \
        curl "https://raw.githubusercontent.com/moby/moby/${DIND_COMMIT}/hack/dind" -o /usr/local/bin/dind; \
        curl "https://raw.githubusercontent.com/docker-library/docker/${DOCKERD_COMMIT}/23.0/dind/dockerd-entrypoint.sh" -o /usr/local/bin/dockerd-entrypoint.sh; \
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
