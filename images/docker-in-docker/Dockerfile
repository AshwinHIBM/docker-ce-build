##
# Build Dind image for docker-ce using locally built docker-ce packages instead of the one from the Debian's repo
# This is inspired from  https://github.com/alunsin/all_in_one_dind/blob/90d0d0df6de2ea4d0666f3e10adce28a5fffcc88/Dockerfile
##

FROM public.ecr.aws/docker/library/debian:bookworm

ENV CONTAINERD_VERSION=1.7.26-1

ENV DOCKER_VERSION=28.0.4-1

WORKDIR /workspace
RUN mkdir -p /workspace
ENV WORKSPACE=/workspace \
    TERM=xterm
RUN apt-get -y update && apt-get -y upgrade && apt-get install -y --no-install-recommends \
    apt-transport-https \
    gnupg2 \
    software-properties-common \
    lsb-release \
    build-essential \
    ca-certificates \
    cmake \
    curl \
    file \
    git \
    libssl-dev \
    make \
    openssh-client \
    pkg-config \
    procps \
    rsync \
    s3fs \
    tini \
    unzip \
    xz-utils \
    zip \
    iptables libdevmapper1.02.1 \
    && rm -rf /var/lib/apt/lists/*

RUN mkdir -p /workspace/tmp

RUN set -eux; \
    \
    dpkgArch="$(dpkg --print-architecture)"; \
    case "${dpkgArch##*-}" in \
        'amd64') \
            curl https://download.docker.com/linux/debian/dists/bookworm/pool/stable/amd64/containerd.io_${CONTAINERD_VERSION}_amd64.deb -o /workspace/tmp/containerd.io_${CONTAINERD_VERSION}_amd64.deb; \
curl https://download.docker.com/linux/debian/dists/bookworm/pool/stable/amd64/docker-ce-cli_${DOCKER_VERSION}~debian.12~bookworm_amd64.deb -o /workspace/tmp/docker-ce-cli_${DOCKER_VERSION}~debian.12~bookworm_amd64.deb ; \
curl https://download.docker.com/linux/debian/dists/bookworm/pool/stable/amd64/docker-ce_${DOCKER_VERSION}~debian.12~bookworm_amd64.deb -o /workspace/tmp/docker-ce_${DOCKER_VERSION}~debian.12~bookworm_amd64.deb ; \
;; \
        'ppc64el') \
curl https://download.docker.com/linux/debian/dists/bookworm/pool/stable/ppc64el/containerd.io_${CONTAINERD_VERSION}_ppc64el.deb -o /workspace/tmp/containerd.io_${CONTAINERD_VERSION}_ppc64el.deb; \
curl https://download.docker.com/linux/debian/dists/bookworm/pool/stable/ppc64el/docker-ce-cli_${DOCKER_VERSION}~debian.12~bookworm_ppc64el.deb -o /workspace/tmp/docker-ce-cli_${DOCKER_VERSION}~debian.12~bookworm_ppc64el.deb; \
curl https://download.docker.com/linux/debian/dists/bookworm/pool/stable/ppc64el/docker-ce_${DOCKER_VERSION}~debian.12~bookworm_ppc64el.deb -o /workspace/tmp/docker-ce_${DOCKER_VERSION}~debian.12~bookworm_ppc64el.deb; \
curl https://download.docker.com/linux/debian/dists/bookworm/pool/stable/ppc64el/docker-buildx-plugin_0.12.1-1~debian.12~bookworm_ppc64el.deb -o /workspace/tmp/docker-buildx-plugin_0.10.5-1~debian.12~bookworm_ppc64el.deb; \
;; \
    esac; \
    \
    dpkg -i /workspace/tmp/*\
    && rm -rf /workspace/tmp; \
    rm -rf /var/lib/apt/lists/*

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

# https://github.com/docker/docker/tree/master/hack/dind
ENV DIND_COMMIT 8d9e3502aba39127e4d12196dae16d306f76993d
ENV DOCKERD_COMMIT 35c016d0c0f0be4dc523bc1108d7fa2681db8306

RUN set -eux; \
curl https://raw.githubusercontent.com/moby/moby/${DIND_COMMIT}/hack/dind -o /usr/local/bin/dind; \
curl https://raw.githubusercontent.com/docker-library/docker/${DOCKERD_COMMIT}/28/dind/dockerd-entrypoint.sh -o /usr/local/bin/dockerd-entrypoint.sh; \
chmod +x /usr/local/bin/dind; \
    chmod +x /usr/local/bin/dockerd-entrypoint.sh; \
cp $(which tini) "/usr/local/bin/docker-init";

RUN mkdir -p /etc/docker; touch /etc/docker/daemon.json; echo "{\"insecure-registries\" : [ \"registry:5000\" ]}" > /etc/docker/daemon.json;


VOLUME /var/lib/docker
EXPOSE 2375 2376

CMD ["dockerd-entrypoint.sh"]