FROM alpine:latest

LABEL org.opencontainers.image.title=test
LABEL org.opencontainers.image.source=https://github.com/libre-devops/azdo-agent-containers

#Set args with blank values - these will be over-written with the CLI
ARG NORMAL_USER=builder

#Set args with blank values - these will be over-written with the CLI
ARG AZP_URL=https://dev.azure.com/Example
ARG AZP_TOKEN=ExamplePatToken
ARG AZP_AGENT_NAME=Example
ARG AZP_POOL=Default
ARG AZP_WORK=_work
ARG AZP_DIRECTORY=/home/$NORMAL_USER
ARG ACCEPT_EULA=y
ARG TARGETARCH="linux-musl-x64"

#Set the environment with the CLI-passed arguements
ENV AZP_URL ${AZP_URL}
ENV AZP_TOKEN ${AZP_TOKEN}
ENV AZP_AGENT_NAME ${AZP_AGENT_NAME}
ENV AZP_POOL ${AZP_POOL}
ENV AZP_WORK ${AZP_WORK}
ENV AZP_DIRECTORY ${AZP_DIRECTORY}
ENV ACCEPT_EULA ${ACCEPT_EULA}
ENV TARGETARCH ${TARGETARCH}

ENV NORMAL_USER ${NORMAL_USER}

# Environment variables for pyenv
ENV HOME /home/${NORMAL_USER}
ENV PYENV_ROOT /home/${NORMAL_USER}/.pyenv
ENV PATH $PYENV_ROOT/shims:$PYENV_ROOT/bin:$PATH

#Set path vars
ENV PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/opt:/opt/bin:/home/linuxbrew/.linuxbrew/bin:/home/linuxbrew/.local/bin:/home/${NORMAL_USER}/.local:/home/${NORMAL_USER}:/home/${NORMAL_USER}/.tenv:/home/${NORMAL_USER}/.tenv/bin:/home/${NORMAL_USER}/.pkenv:/home/${NORMAL_USER}/.pkenv/bin:/home/${NORMAL_USER}/.pyenv:/home/${NORMAL_USER}/.pyenv/bin:/home/${NORMAL_USER}/.pyenv/shims:/home/${NORMAL_USER}/.local/bin"
ENV PATHVAR="PATH=${PATH}"

USER root

RUN adduser -s /bin/bash -D -h /home/${NORMAL_USER} ${NORMAL_USER} && \
    echo '@edge https://dl-cdn.alpinelinux.org/alpine/edge/testing' >> /etc/apk/repositories && \
    apk add --no-cache \
    bash \
    build-base \
    bzip2-dev \
    coreutils \
    cosign \
    curl \
    dos2unix \
    git \
    icu-libs \
    jq \
    libffi-dev \
    libxml2-dev \
    libxslt-dev \
    linux-headers \
    nano \
    ncurses-dev \
    openssl-dev \
    openssl1.1-compat@edge \
    readline-dev \
    sqlite-dev \
    sudo \
    tk-dev \
    xz-dev && \
    apk -X https://dl-cdn.alpinelinux.org/alpine/edge/main add --no-cache \
    lttng-ust && \
    echo $PATHVAR > /etc/environmentecho $PATHVAR > /etc/environment
