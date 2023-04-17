#Use supplier image
FROM docker.io/ubuntu:latest

RUN rm -rf /bin/sh && ln -sf /bin/bash /bin/sh
LABEL org.opencontainers.image.source=https://github.com/libre-devops/azdo-agent-containers

ARG DEBIAN_FRONTEND=noninteractive
ENV ACCEPT_EULA ${ACCEPT_EULA}

#Set args with blank values - these will be over-written with the CLI
ARG AZP_URL=https://dev.azure.com/Example
ARG AZP_TOKEN=ExamplePatToken
ARG AZP_AGENT_NAME=Example
ARG AZP_POOL=PoolName
ARG AZP_WORK=_work
ARG NORMAL_USER=azp
ARG USER_PASSWORD=azp

#Set the environment with the CLI-passed arguements
ENV AZP_URL ${AZP_URL}
ENV AZP_AGENT_NAME ${AZP_AGENT_NAME}
ENV AZP_POOL ${AZP_POOL}
ENV AZP_WORK ${AZP_WORK}
ENV NORMAL_USER ${NORMAL_USER}

#Set path vars
ENV PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/opt:/opt/bin:/home/linuxbrew/.linuxbrew/bin:/home/linuxbrew/.local/bin:/home/${NORMAL_USER}/.pyenv:/home/${NORMAL_USER}/.pyenv/bin:/home/${NORMAL_USER}/.local:/home/${NORMAL_USER}/.tfenv:/home/${NORMAL_USER}/.tfenv/bin:/home/${NORMAL_USER}/.pkenv:/home/${NORMAL_USER}/.pkenv/bin:/home/${NORMAL_USER}/.goenv:/home/${NORMAL_USER}/.goenv/bin:/home/${NORMAL_USER}/.jenv:/home/${NORMAL_USER}/.jenv/bin:/home/${NORMAL_USER}/.nvm:/home/${NORMAL_USER}/.rbenv:/home/${NORMAL_USER}/.rbenv/bin:/home/${NORMAL_USER}/.sdkman:/home/${NORMAL_USER}/.sdkman/bin:/home/${NORMAL_USER}/.dotnet:/home/${NORMAL_USER}/.cargo:/home/${NORMAL_USER}/.cargo/bin:/home/${NORMAL_USER}/.phpenv:/home/${NORMAL_USER}/.phpenv/bin"
ENV PATHVAR="PATH=${PATH}"

ENV JAVA_HOME="/home/${NORMAL_USER}/.sdkman/candidates/java/current/bin/java"
ENV NVM_DIR="/home/${NORMAL_USER}/.nvm"
#Declare user expectation, I am performing root actions, so use root.
USER root

RUN mkdir -p /azp && \
    useradd -ms /bin/bash ${NORMAL_USER} && \
    usermod -aG sudo ${NORMAL_USER} && \
    echo "${NORMAL_USER}:${USER_PASSWORD}" | chpasswd && \
    chown -R ${NORMAL_USER} /azp && \
    mkdir -p /home/linuxbrew && \
    chown -R ${NORMAL_USER} /home/linuxbrew && \
    apt-get update -y && apt-get dist-upgrade -y && apt-get install -y \
    apt-transport-https \
    bash \
    build-essential \
    ca-certificates \
    curl \
    gcc \
    git \
    gnupg \
    gnupg2 \
    jq \
    libbz2-dev \
    libcurl4-gnutls-dev \
    libffi-dev \
    libjpeg-dev \
    liblzma-dev \
    libonig-dev \
    libpng-dev \
    libreadline-dev \
    libsqlite3-dev \
    libssl-dev \
    libtidy-dev \
    libxml2-dev \
    libyaml-dev \
    libzip-dev \
    make \
    openssl \
    pkg-config \
    python-is-python3 \
    python3-pip \
    python3-tk \
    python3-venv \
    sudo \
    unzip \
    wget \
    zip \
    zlib1g-dev && \
    curl -sSLo packages-microsoft-prod.deb https://packages.microsoft.com/config/ubuntu/$(grep -oP '(?<=^DISTRIB_RELEASE=).+' /etc/lsb-release | tr -d '"')/packages-microsoft-prod.deb && \
    dpkg -i packages-microsoft-prod.deb && \
    rm -rf packages-microsoft-prod.deb && \
    apt-get update && \
    apt-get install -y powershell && \
    ln -sf /bin/pwsh /bin/powershell && \
    apt-get update && \
    apt-get autoremove -y && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* && \
    echo $PATHVAR > /etc/environment

USER ${NORMAL_USER}
WORKDIR /home/${NORMAL_USER}

# Install homebrew and gcc per recomendation
RUN echo -en "\n" | /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" && \
    echo 'eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"' >> /home/${NORMAL_USER}/.bashrc && \
    eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)" && \
    brew install gcc

# Install Python
RUN git clone https://github.com/pyenv/pyenv.git ~/.pyenv && \
    # Fetch the latest stable version number of Python from python.org
    PYTHON_LATEST_VERSION=$(curl -s https://www.python.org/downloads/ | grep -oP 'Download Python \K[0-9.]+(?=<)' | head -n 1) && \
    PYTHON_MAJOR_VERSION=$(echo "$PYTHON_LATEST_VERSION" | cut -d '.' -f 1) && \
    PYTHON_MINOR_VERSION=$(echo "$PYTHON_LATEST_VERSION" | cut -d '.' -f 2) && \
    PYTHON_VERSION="${PYTHON_MAJOR_VERSION}.${PYTHON_MINOR_VERSION}" && \
    echo 'export PYENV_ROOT="$HOME/.pyenv"' >> ~/.bashrc && \
    echo 'command -v pyenv >/dev/null || export PATH="$PYENV_ROOT/bin:$PATH"' >> ~/.bashrc && \
    echo 'eval "$(pyenv init -)"' >> ~/.bashrc && \
    echo 'export PATH=$HOME/.local:$PATH' >> ~/.bashrc && \
    source ~/.bashrc && \
    pyenv install ${PYTHON_VERSION} && \
    pyenv global ${PYTHON_VERSION}

# Install Terraform env
RUN git clone --depth=1 https://github.com/tfutils/tfenv.git ~/.tfenv && \
    echo 'export PATH=${HOME}/.tfenv/bin:${PATH}' >> ~/.bashrc  && \
    source ~/.bashrc && \
    tfenv install latest && \
    tfenv use latest

# Install Packer Env
RUN git clone https://github.com/iamhsa/pkenv.git ~/.pkenv && \
    echo 'export PATH="${HOME}/.pkenv/bin:${PATH}"' >> ~/.bashrc && \
    PACKER_LATEST_URL=$(curl -sL https://releases.hashicorp.com/packer/index.json | jq -r '.versions[].builds[].url' | egrep -v 'rc|beta|alpha' | egrep 'linux.*amd64'  | tail -1) && \
    PACKER_LATEST_VERSION=$(echo "$PACKER_LATEST_URL" | awk -F '/' '{print $6}' | sed 's/packer_//' | sed 's/_linux_amd64.zip//') && \
    source ~/.bashrc && \
    pkenv install ${PACKER_LATEST_VERSION} && \
    pkenv use ${PACKER_LATEST_VERSION}

# Install Ruby
RUN git clone https://github.com/rbenv/rbenv.git ~/.rbenv && \
    echo 'eval "$(~/.rbenv/bin/rbenv init - bash)"' >> ~/.bashrc && \
    source ~/.bashrc && \
    git clone https://github.com/rbenv/ruby-build.git "$(rbenv root)"/plugins/ruby-build && \
    RUBY_LATEST_VERSION=$(curl -s https://www.ruby-lang.org/en/downloads/ | grep -oP 'The current stable version is \K[0-9.]+' | sed 's/\.$//') && \
    rbenv install ${RUBY_LATEST_VERSION} && \
    rbenv global ${RUBY_LATEST_VERSION}

# Install Go
RUN git clone https://github.com/syndbg/goenv.git ~/.goenv && \
    echo 'export GOENV_ROOT="${HOME}/.goenv"' >> ~/.bashrc && \
    echo 'export PATH="${GOENV_ROOT}/bin:${PATH}"' >> ~/.bashrc && \
    echo 'eval "$(goenv init -)"' >> ~/.bashrc && \
    echo 'export PATH="${GOROOT}/bin:${PATH}"' >> ~/.bashrc && \
    echo 'export PATH="${PATH}:${GOPATH}/bin"' >> ~/.bashrc && \
    source ~/.bashrc && \
    GO_LATEST_VERSION=$(goenv install -l | grep -E -o '[0-9]+\.[0-9]+(\.[0-9]+)?' | tail -1) && \
    goenv install ${GO_LATEST_VERSION} && \
    goenv global ${GO_LATEST_VERSION}


# Install Dotnet SDK non-interactively
RUN curl -L dotnet-install.sh https://dot.net/v1/dotnet-install.sh | bash

# Install Rust non-interactively
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | bash -s -- -y

# Install NVM and Node.JS LTS
RUN curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.3/install.sh | bash && \
    source ~/.bashrc && \
    nvm install --lts && \
    nvm use --lts \

# Install SDKMAN! since all Java venvs are annoying
RUN curl -s "https://get.sdkman.io" | bash && \
    source "$HOME/.sdkman/bin/sdkman-init.sh" && \
    MICROSOFT_LATEST_OPENJDK=$(sdk list java | grep ms | grep -E -o '[0-9]+\.[0-9]+\.[0-9]+-ms' | head -1) && \
    sdk install java ${MICROSOFT_LATEST_OPENJDK} && \
    sdk use java ${MICROSOFT_LATEST_OPENJDK}

COPY start.sh /home/${NORMAL_USER}/start.sh
RUN chmod 755 start.sh
CMD [ "./start.sh" ]
