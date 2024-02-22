FROM alpine:latest

LABEL org.opencontainers.image.title=alpine
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

# Download the PowerShell '.tar.gz' archive
RUN POWERSHELL_RELEASE_URL=$(curl -s -L https://api.github.com/repos/PowerShell/PowerShell/releases/latest | jq -r '.assets[] | select(.name | endswith("linux-musl-x64.tar.gz")) | .browser_download_url') && \
    curl -L $POWERSHELL_RELEASE_URL -o /tmp/powershell.tar.gz && \
    mkdir -p /opt/microsoft/powershell/7 && \
    tar zxf /tmp/powershell.tar.gz -C /opt/microsoft/powershell/7 && \
    chmod +x /opt/microsoft/powershell/7/pwsh && \
    ln -s /opt/microsoft/powershell/7/pwsh /usr/bin/pwsh && \
    ln -s /usr/bin/pwsh /usr/bin/powershell

## Install pyenv and the latest stable version of Python
RUN git clone https://github.com/pyenv/pyenv.git /home/${NORMAL_USER}/.pyenv && \
    eval "$(pyenv init --path)" && \
    pyenvLatestStable=$(pyenv install --list | grep -v - | grep -E "^\s*[0-9]+\.[0-9]+\.[0-9]+$" | tail -1) && \
    pyenv install $pyenvLatestStable && \
    pyenv global $pyenvLatestStable && \
    pip install --upgrade pip

#Install Azure Modules for Powershell - This can take a while, so setting as final step to shorten potential rebuilds
RUN pwsh -Command Set-PSRepository -Name "PSGallery" -InstallationPolicy Trusted && \
    pwsh -Command Install-Module -Name Az -Force -AllowClobber -Scope AllUsers -Repository PSGallery && \
    pwsh -Command Install-Module -Name Microsoft.Graph -Force -AllowClobber -Scope AllUsers -Repository PSGallery && \
    pwsh -Command Install-Module -Name Pester -Force -AllowClobber -Scope AllUsers -Repository PSGallery


RUN LATEST_VERSION=$(curl --silent https://api.github.com/repos/tofuutils/tenv/releases/latest|jq -r .tag_name) && \
    curl -O -L "https://github.com/tofuutils/tenv/releases/latest/download/tenv_${LATEST_VERSION}_amd64.apk" && \
    apk add --allow-untrusted "tenv_${LATEST_VERSION}_amd64.apk"

# Install Packer Env
RUN git clone https://github.com/iamhsa/pkenv.git /home/${NORMAL_USER}/.pkenv && \
    PACKER_LATEST_URL=$(curl -sL https://releases.hashicorp.com/packer/index.json | jq -r '.versions[].builds[].url' | egrep -v 'rc|beta|alpha' | egrep 'linux.*amd64'  | tail -1) && \
    PACKER_LATEST_VERSION=$(echo "$PACKER_LATEST_URL" | awk -F '/' '{print $6}' | sed 's/packer_//' | sed 's/_linux_amd64.zip//') && \
    pkenv install ${PACKER_LATEST_VERSION} && \
    pkenv use ${PACKER_LATEST_VERSION}

RUN chown -R ${NORMAL_USER}:${NORMAL_USER} /opt && \
    chown -R ${NORMAL_USER}:${NORMAL_USER} /home/${NORMAL_USER}

RUN curl -sL $(curl -sL https://api.github.com/repos/aquasecurity/trivy/releases/latest | jq -r '.assets[] | select(.name | test("Linux-64bit\\.tar\\.gz$")) | .browser_download_url') -o /tmp/trivy.tar.gz && \
    tar zxvf /tmp/trivy.tar.gz -C /tmp && \
    chmod +x /tmp/trivy && \
    mv /tmp/trivy /usr/local/bin/

COPY start.sh /home/${NORMAL_USER}/start.sh
COPY env.sh /home/${NORMAL_USER}/env.sh
RUN chmod +x /home/${NORMAL_USER}/start.sh && \
    chmod +x /home/${NORMAL_USER}/env.sh && \
    chown -R "${NORMAL_USER}:${NORMAL_USER}" /home/${NORMAL_USER}

USER ${NORMAL_USER}
WORKDIR /home/${NORMAL_USER}
CMD [ "./start.sh" ]

USER ${NORMAL_USER}
WORKDIR /home/${NORMAL_USER}

RUN tenv tf install latest --verbose && \
    tenv tf use latest --verbose && \
    tenv tofu install latest --verbose && \
    tenv tofu use latest --verbose && \
    tenv tg install latest --verbose && \
    tenv tg use latest --verbose

RUN pip3 install --user \
    pipenv \
    virtualenv \
    terraform-compliance \
    checkov \
    pywinrm

# Install Azure-CLI as seperate step for cacheing speed
RUN pip3 install --user azure-cli
