FROM ubuntu:latest

LABEL org.opencontainers.image.title=ubuntu
LABEL org.opencontainers.image.source=https://github.com/libre-devops/azdo-agent-containers

RUN rm -rf /bin/sh && ln -sf /bin/bash /bin/sh

#Set args with blank values - these will be over-written with the CLI
ARG NORMAL_USER=builder
ARG DEBIAN_FRONTEND=noninteractive

#Set args with blank values - these will be over-written with the CLI
ARG AZP_URL=https://dev.azure.com/Example
ARG AZP_TOKEN=ExamplePatToken
ARG AZP_AGENT_NAME=Example
ARG AZP_POOL=Default
ARG AZP_WORK=_work
ARG AZP_DIRECTORY=/home/$NORMAL_USER
ARG ACCEPT_EULA=y
ARG TARGETARCH="linux-x64"

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
ENV DEBIAN_FRONTEND=noninteractive

# Environment variables for pyenv
ENV HOME /home/${NORMAL_USER}
ENV PYENV_ROOT /home/${NORMAL_USER}/.pyenv
ENV PATH $PYENV_ROOT/shims:$PYENV_ROOT/bin:$PATH

#Set path vars
ENV PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/opt:/opt/bin:/home/linuxbrew/.linuxbrew/bin:/home/linuxbrew/.local/bin:/home/${NORMAL_USER}/.pyenv:/home/${NORMAL_USER}/.pyenv/bin:/home/${NORMAL_USER}/.local:/home/${NORMAL_USER}/.tenv:/home/${NORMAL_USER}/.tenv/bin:/home/${NORMAL_USER}/.pkenv:/home/${NORMAL_USER}/.pkenv/bin:/home/${NORMAL_USER}/.goenv:/home/${NORMAL_USER}/.goenv/bin:/home/${NORMAL_USER}/.jenv:/home/${NORMAL_USER}/.jenv/bin:/home/${NORMAL_USER}/.nvm:/home/${NORMAL_USER}/.rbenv:/home/${NORMAL_USER}/.rbenv/bin:/home/${NORMAL_USER}/.sdkman:/home/${NORMAL_USER}/.sdkman/bin:/home/${NORMAL_USER}/.dotnet:/home/${NORMAL_USER}/.cargo:/home/${NORMAL_USER}/.cargo/bin:/home/${NORMAL_USER}/.phpenv:/home/${NORMAL_USER}/.phpenv/bin:/home/${NORMAL_USER}:/home/${NORMAL_USER}/.pyenv/shims:/home/${NORMAL_USER}/.local/bin"
ENV PATHVAR="PATH=${PATH}"

USER root

# Install necessary libraries for pyenv and other dependencies
RUN useradd -ms /bin/bash ${NORMAL_USER} && \
    mkdir -p /home/linuxbrew && \
    chown -R ${NORMAL_USER}:${NORMAL_USER} /home/linuxbrew && \
    apt-get update && \
    apt-get dist-upgrade -y && \
    apt-get install -y \
    apt-transport-https \
    bash \
    libbz2-dev \
    ca-certificates \
    curl \
    dos2unix \
    dotnet-sdk-8.0 \
    gcc \
    gnupg \
    gnupg2 \
    git \
    jq \
    libffi-dev \
    libicu-dev \
    make \
    nano \
    software-properties-common \
    libsqlite3-dev \
    libssl-dev \
    unzip \
    wget \
    zip \
    zlib1g-dev \
    build-essential \
    sudo \
    libreadline-dev \
    llvm \
    libncurses5-dev \
    xz-utils \
    tk-dev \
    libxml2-dev \
    libxmlsec1-dev \
    liblzma-dev && \
    echo $PATHVAR > /etc/environment && \
    LATEST_VERSION=$(curl https://api.github.com/repos/sigstore/cosign/releases/latest | jq -r .tag_name | tr -d "v\", ") && \
    curl -O -L "https://github.com/sigstore/cosign/releases/latest/download/cosign_${LATEST_VERSION}_amd64.deb" && \
    sudo dpkg -i cosign_${LATEST_VERSION}_amd64.deb

# Install pyenv and the latest stable version of Python
RUN git clone https://github.com/pyenv/pyenv.git /home/${NORMAL_USER}/.pyenv && \
    eval "$(pyenv init --path)" && \
    pyenvLatestStable=$(pyenv install --list | grep -v - | grep -E "^\s*[0-9]+\.[0-9]+\.[0-9]+$" | tail -1) && \
    pyenv install $pyenvLatestStable && \
    pyenv global $pyenvLatestStable && \
    pip install --upgrade pip

# Install PowerShell
RUN curl -sSLO https://packages.microsoft.com/config/ubuntu/$(grep -oP '(?<=^DISTRIB_RELEASE=).+' /etc/lsb-release | tr -d '"')/packages-microsoft-prod.deb && \
    dpkg -i packages-microsoft-prod.deb && \
    rm -f packages-microsoft-prod.deb && \
    apt-get update && \
    apt-get install -y powershell && \
    ln -s /usr/bin/pwsh /usr/bin/powershell

RUN curl -Lo bicep https://github.com/Azure/bicep/releases/latest/download/bicep-linux-x64 && \
    chmod +x ./bicep && \
    sudo mv ./bicep /usr/local/bin/bicep

#Install Azure Modules for Powershell - This can take a while, so setting as final step to shorten potential rebuilds
RUN pwsh -Command Set-PSRepository -Name "PSGallery" -InstallationPolicy Trusted && \
    pwsh -Command Install-Module -Name Az -Force -AllowClobber -Scope AllUsers -Repository PSGallery && \
    pwsh -Command Install-Module -Name Microsoft.Graph -Force -AllowClobber -Scope AllUsers -Repository PSGallery && \
    pwsh -Command Install-Module -Name Pester -Force -AllowClobber -Scope AllUsers -Repository PSGallery && \
    pwsh -Command Install-Module -Name LibreDevOpsHelpers -Force -AllowClobber -Scope AllUsers -Repository PSGallery



RUN LATEST_VERSION=$(curl --silent https://api.github.com/repos/tofuutils/tenv/releases/latest|jq -r .tag_name) && \
    curl -O -L "https://github.com/tofuutils/tenv/releases/latest/download/tenv_${LATEST_VERSION}_amd64.deb" && \
    sudo dpkg -i "tenv_${LATEST_VERSION}_amd64.deb"

# Install Packer Env
RUN git clone https://github.com/iamhsa/pkenv.git /home/${NORMAL_USER}/.pkenv && \
    PACKER_LATEST_URL=$(curl -sL https://releases.hashicorp.com/packer/index.json | jq -r '.versions[].builds[] | select(.arch=="amd64" and .os=="linux" and (.name|test("alpha|beta|rc")==false)) | .url' | sort -V | tail -1) && \
    PACKER_LATEST_VERSION=$(echo "$PACKER_LATEST_URL" | awk -F '/' '{print $6}' | sed 's/packer_//' | sed 's/_linux_amd64.zip//') && \
    pkenv install ${PACKER_LATEST_VERSION} && \
    pkenv use ${PACKER_LATEST_VERSION}

RUN chown -R ${NORMAL_USER}:${NORMAL_USER} /opt && \
    chown -R ${NORMAL_USER}:${NORMAL_USER} /home/${NORMAL_USER} && \
    apt-get update && \
    apt-get autoremove -y && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

COPY start.sh /home/${NORMAL_USER}/start.sh
COPY env.sh /home/${NORMAL_USER}/env.sh
RUN chmod +x /home/${NORMAL_USER}/start.sh && \
    chmod +x /home/${NORMAL_USER}/env.sh && \
    chown -R "${NORMAL_USER}:${NORMAL_USER}" /home/${NORMAL_USER}

USER ${NORMAL_USER}
WORKDIR /home/${NORMAL_USER}
CMD [ "./start.sh" ]

RUN tenv tf install latest --verbose && \
    tenv tf use latest --verbose && \
    tenv tofu install latest --verbose && \
    tenv tofu use latest --verbose

RUN pip3 install --user \
    pipenv \
    virtualenv \
    terraform-compliance \
    pywinrm

# Install Azure-CLI as seperate step for cacheing speed
RUN pip3 install --user azure-cli

# Install homebrew and gcc per recomendation as well a PHP
RUN echo -en "\n" | /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" && \
    echo 'eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"' >> /home/${NORMAL_USER}/.bashrc && \
    eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)" && \
    brew install gcc && \
    brew install trivy && \
    brew install pipx && \
    brew install checkov && \
    brew tap azure/functions && \
    brew install azure-functions-core-tools@4

