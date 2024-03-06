##
# Build image for docker-ce by installing packages
##

FROM debian:bookworm
RUN apt-get -y update; \
    apt-get -y install sudo;  \
    sudo apt-get -y install ca-certificates curl; \
    sudo install -m 0755 -d /etc/apt/keyrings; \
    sudo curl -fsSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc; \
    sudo chmod a+r /etc/apt/keyrings/docker.asc; \
RUN echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/debian \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
RUN sudo apt-get update; \
    sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

ENTRYPOINT ["/bin/bash", "-c", "sleep", "10000"]