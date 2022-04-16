#Use supplier image
FROM docker.io/ubuntu:jammy

LABEL org.opencontainers.image.source=https://github.com/libre-devops/azdo-agent-containers

#Set args with blank values - these will be over-written with the CLI
ARG NORMAL_USER=lbdo
ARG PYTHON3_VERSION=3.10.4
ARG DOTNET_VERSION=6.0
ARG GO_VERSION=1.18.1
ARG JAVA_VERSION=17

ENV ACCEPT_EULA ${ACCEPT_EULA}
ENV PYTHON3_VERSION ${PYTHON3_VERSION}
ENV DOTNET_VERSION ${DOTNET_VERSION}
ENV GO_VERSION ${GO_VERSION}
ENV JAVA_VERSION ${JAVA_VERSION}
ENV NORMAL_USER ${NORMAL_USER}

#Set args with blank values - these will be over-written with the CLI
ARG AZP_URL=https://dev.azure.com/Example
ARG AZP_TOKEN=ExamplePatToken
ARG AZP_AGENT_NAME=Example
ARG AZP_POOL=PoolName
ARG AZP_WORK=_work
ARG NORMAL_USER=azp

#Set the environment with the CLI-passed arguements
ENV AZP_URL ${AZP_URL}
ENV AZP_TOKEN ${AZP_TOKEN}
ENV AZP_AGENT_NAME ${AZP_AGENT_NAME}
ENV AZP_POOL ${AZP_POOL}
ENV AZP_WORK ${AZP_WORK}
ENV NORMAL_USER ${NORMAL_USER}

#Declare user expectation, I am performing root actions, so use root.
USER root

#Install needed packages as well as setup python with args and pip
RUN mkdir -p /azp && \
    #Make unpriviledged user
    useradd -ms /bin/bash ${NORMAL_USER} && \
    chown -R ${NORMAL_USER} /azp && \
    apt-get update -y && apt-get dist-upgrade -y && apt-get install -y \
    apt-transport-https \
    bash \
    libbz2-dev \
    ca-certificates \
    curl \
    gcc \
    gnupg \
    gnupg2 \
    git \
    jq \
    libffi-dev \
    libicu-dev \
    make \
    software-properties-common \
    libsqlite3-dev \
    libssl-dev\
    unzip \
    wget \
    zip  \
    zlib1g-dev && \
              wget https://www.python.org/ftp/python/${PYTHON3_VERSION}/Python-${PYTHON3_VERSION}.tgz && \
              tar xzf Python-${PYTHON3_VERSION}.tgz && rm -rf tar xzf Python-${PYTHON3_VERSION}.tgz && \
              cd Python-${PYTHON3_VERSION} && ./configure --enable-optimizations --enable-loadable-sqlite-extensions && \
              make install && cd .. && rm -rf Python-${PYTHON3_VERSION} && \
              export PATH=$PATH:/usr/local/bin/python3 && curl https://bootstrap.pypa.io/get-pip.py -o get-pip.py && \
              python3 get-pip.py && pip3 install virtualenv && rm -rf get-pip.py && \
                pip3 install --upgrade pip && \
                pip3 install azure-cli && \
                pip3 install --upgrade azure-cli && \
                pip3 install ansible terraform-compliance pywinrm checkov pipenv virtualenv && \
                mkdir -p /home/linuxbrew && \
                chown -R ${NORMAL_USER}:${NORMAL_USER} /home/linuxbrew && \
                az config set extension.use_dynamic_install=yes_without_prompt

# Hack powershell install
RUN  echo "deb [arch=amd64,armhf,arm64 signed-by=/usr/share/keyrings/powershell.gpg] \
https://packages.microsoft.com/ubuntu/20.04/prod focal main" \
| tee /etc/apt/sources.list.d/powershell.list && \
curl https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor | tee /usr/share/keyrings/powershell.gpg >/dev/null && \
apt-get update && \
wget http://archive.ubuntu.com/ubuntu/pool/main/o/openssl/libssl1.1_1.1.0g-2ubuntu4_amd64.deb && \
dpkg -i libssl1.1_1.1.0g-2ubuntu4_amd64.deb && \
apt-get install powershell -y


RUN terraformLatestVersion=$(curl -sL https://releases.hashicorp.com/terraform/index.json | jq -r '.versions[].builds[].url' | egrep -v 'rc|beta|alpha' | egrep 'linux.*amd64'  | tail -1) && \
    wget "${terraformLatestVersion}" && \
    unzip terraform* && rm -rf terraform*.zip && \
    mv terraform /usr/local/bin && \
    packerLatestVersion=$(curl -sL https://releases.hashicorp.com/packer/index.json | jq -r '.versions[].builds[].url' | egrep -v 'rc|beta|alpha' | egrep 'linux.*amd64'  | tail -1) && \
    wget "${packerLatestVersion}" && \
    unzip packer* && rm -rf packer*.zip && \
    mv packer /usr/local/bin

RUN rm -rf /usr/local/go && \
    wget https://storage.googleapis.com/golang/go${GO_VERSION}.linux-amd64.tar.gz && \
    tar -C /usr/local -xzf go${GO_VERSION}.linux-amd64.tar.gz && \
    export PATH=$PATH:/usr/local/go/bin && \
    export GOPATH=/usr/local/go/dev && \
    export PATH=$PATH:$GOPATH/bin && \
    rm -rf go${GO_VERSION}.linux-amd64.tar.gz && \
    GO111MODULE="on" go install github.com/terraform-docs/terraform-docs@latest && \
    GO111MODULE="on" go install github.com/aquasecurity/tfsec/cmd/tfsec@latest

RUN curl -s "https://get.sdkman.io" | bash && \
    nvmLatest=$(curl --silent "https://api.github.com/repos/nvm-sh/nvm/releases/latest" | jq -r .tag_name) && \
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/${nvmLatest}/install.sh | bash

#Don't include container-selinux and remove
#directories used by yum that are just taking
#up space.
RUN apt-get update && apt-get -y install container-tools && \
apt-get install -y crun podman podman-docker fuse-overlayfs

RUN useradd podman; \
echo podman:10000:5000 > /etc/subuid; \
echo podman:10000:5000 > /etc/subgid;

VOLUME /var/lib/containers
RUN mkdir -p /home/podman/.local/share/containers
RUN chown podman:podman -R /home/podman && usermod -aG podman ${NORMAL_USER}
VOLUME /home/podman/.local/share/containers

#https://raw.githubusercontent.com/containers/libpod/master/contrib/podmanimage/stable/containers.conf
ADD containers.conf /etc/containers/containers.conf
#https://raw.githubusercontent.com/containers/libpod/master/contrib/podmanimage/stable/podman-containers.conf
ADD podman-containers.conf /home/podman/.config/containers/containers.conf

#chmod containers.conf and adjust storage.conf to enable Fuse storage.
RUN chmod 644 /etc/containers/containers.conf; sed -i -e 's|^#mount_program|mount_program|g' -e '/additionalimage.*/a "/var/lib/shared",' -e 's|^mountopt[[:space:]]*=.*$|mountopt = "nodev,fsync=0"|g' /etc/containers/storage.conf
RUN mkdir -p /var/lib/shared/overlay-images /var/lib/shared/overlay-layers /var/lib/shared/vfs-images /var/lib/shared/vfs-layers; \
    touch /var/lib/shared/overlay-images/images.lock; \
    touch /var/lib/shared/overlay-layers/layers.lock; \
    touch /var/lib/shared/vfs-images/images.lock; \
    touch /var/lib/shared/vfs-layers/layers.lock

ENV _CONTAINERS_USERNS_CONFIGURED=""

#Prepare container for Azure DevOps script execution
WORKDIR /azp
COPY start.sh /azp/start.sh
CMD [ "./start.sh" ]

#Install Azure Modules for Powershell - This can take a while, so setting as final step to shorten potential rebuilds
RUN pwsh -Command Set-PSRepository -Name "PSGallery" -InstallationPolicy Trusted ; pwsh -Command Install-Module -Name Az -Force -AllowClobber -Scope AllUsers -Repository PSGallery

#Set as unpriviledged user for default container execution
USER ${NORMAL_USER}

RUN echo -en "\n" | /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" && \
    echo 'eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"' >> /home/${NORMAL_USER}/.bash_profile && \
    eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)" && \
    source ~/.bash_profile && source ~/.bashrc && \
    curl -s "https://get.sdkman.io" | bash && \
    source "$HOME/.sdkman/bin/sdkman-init.sh" && \
    az config set extension.use_dynamic_install=yes_without_prompt

USER root

ENV GOPATH=/usr/local/go/dev

#Set User Path with expected paths for new packages
ENV PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/local/go/bin:/usr/local/go:/usr/local/go/dev/bin:/usr/local/bin/python3:/home/linuxbrew/.linuxbrew/bin:/home/${NORMAL_USER}/.local/bin:${PATH}"

#Install User Packages
RUN pip3 install --user \
    checkov \
    pipenv \
    terraform-compliance \
    virtualenv && \
        echo 'alias powershell="pwsh"' >> /home/${NORMAL_USER}/.bashrc && \
        echo 'alias powershell="pwsh"' >> /root/.bashrc

USER ${NORMAL_USER}

WORKDIR /azp
