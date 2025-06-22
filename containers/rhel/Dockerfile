#Use supplier image
FROM registry.access.redhat.com/ubi9/ubi:latest

LABEL org.opencontainers.image.title=rhel
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
ENV PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/opt:/opt/bin:/home/linuxbrew/.linuxbrew/bin:/home/linuxbrew/.local/bin:/home/${NORMAL_USER}/.local:/home/${NORMAL_USER}:/home/${NORMAL_USER}/.tenv:/home/${NORMAL_USER}/.tenv/bin:/home/${NORMAL_USER}/.pkenv:/home/${NORMAL_USER}/.pkenv/bin:/home/${NORMAL_USER}/.pyenv:/home/${NORMAL_USER}/.pyenv/bin:/home/${NORMAL_USER}/.pyenv/shims:/home/${NORMAL_USER}/.local/bin"
ENV PATHVAR="PATH=${PATH}"

# RHEL9 doesn't have readline-devel in the standard repos
ENV READLINE_DEVEL_VERSION="8.1-4"

#Declare user expectation, I am performing root actions, so use root.
USER root

#Install needed packages as well as setup python with args and pip
RUN useradd -ms /bin/bash ${NORMAL_USER} && \
    mkdir -p /home/linuxbrew && \
    chown -R ${NORMAL_USER}:${NORMAL_USER} /home/linuxbrew && \
    dnf update -y && dnf upgrade -y && dnf install -y yum-utils dnf sudo && \
    MAJOR_OS_VERSION=$(grep VERSION_ID /etc/os-release | cut -d '"' -f 2 | cut -d '.' -f 1) && \
    rpm -ivh https://dl.fedoraproject.org/pub/epel/epel-release-latest-${MAJOR_OS_VERSION}.noarch.rpm && \
    /usr/bin/crb enable && \
    sudo dnf install -y \
    bash \
    bzip2-devel \
    ca-certificates \
    gcc \
    git \
    gnupg \
    gnupg2 \
    jq \
    libffi-devel \
    libicu-devel \
    make \
    nano \
    ncurses-devel \
    openssl-devel \
    procps-ng \
    sqlite-devel \
    unzip \
    wget \
    xz-devel \
    zip  \
    zlib-devel && \
    echo $PATHVAR > /etc/environment && \
    LATEST_VERSION=$(curl https://api.github.com/repos/sigstore/cosign/releases/latest | jq -r .tag_name | tr -d "v\", ") && \
    curl -O -L "https://github.com/sigstore/cosign/releases/latest/download/cosign-${LATEST_VERSION}-1.x86_64.rpm" && \
    rpm -ivh cosign-${LATEST_VERSION}-1.x86_64.rpm && \
    curl -O https://mirror.stream.centos.org/9-stream/AppStream/x86_64/os/Packages/readline-devel-${READLINE_DEVEL_VERSION}.el9.x86_64.rpm && \
    dnf install -y readline-devel-${READLINE_DEVEL_VERSION}.el9.x86_64.rpm

RUN POWERSHELL_RELEASE_URL=$(curl -s -L https://api.github.com/repos/PowerShell/PowerShell/releases/latest | jq -r '.assets[] | select(.name | endswith("linux-x64.tar.gz")) | .browser_download_url') && \
    curl -L $POWERSHELL_RELEASE_URL -o /tmp/powershell.tar.gz && \
    mkdir -p /opt/microsoft/powershell/7 && \
    tar zxf /tmp/powershell.tar.gz -C /opt/microsoft/powershell/7 && \
    chmod +x /opt/microsoft/powershell/7/pwsh && \
    ln -s /opt/microsoft/powershell/7/pwsh /usr/bin/pwsh && \
    ln -s /usr/bin/pwsh /usr/bin/powershell

RUN git clone https://github.com/pyenv/pyenv.git /home/${NORMAL_USER}/.pyenv && \
    eval "$(pyenv init --path)" && \
    pyenvLatestStable=$(pyenv install --list | grep -v - | grep -E "^\s*[0-9]+\.[0-9]+\.[0-9]+$" | tail -1) && \
    pyenv install $pyenvLatestStable && \
    pyenv global $pyen vLatestStable && \
    pip install --upgrade pip && \
    pip install pipx

#Install Azure Modules for Powershell - This can take a while, so setting as final step to shorten potential rebuilds
RUN pwsh -Command Set-PSRepository -Name "PSGallery" -InstallationPolicy Trusted && \
    pwsh -Command Install-Module -Name Az -Force -AllowClobber -Scope AllUsers -Repository PSGallery && \
    pwsh -Command Install-Module -Name Microsoft.Graph -Force -AllowClobber -Scope AllUsers -Repository PSGallery && \
    pwsh -Command Install-Module -Name Pester -Force -AllowClobber -Scope AllUsers -Repository PSGallery && \
    pwsh -Command Install-Module -Name LibreDevOpsHelpers -Force -AllowClobber -Scope AllUsers -Repository PSGallery && \
    pwsh -Command Install-Module Microsoft.PowerShell.PSResourceGet -AllowClobber -Scope AllUsers -Repository PSGallery



RUN LATEST_VERSION=$(curl --silent https://api.github.com/repos/tofuutils/tenv/releases/latest|jq -r .tag_name) && \
    curl -O -L "https://github.com/tofuutils/tenv/releases/latest/download/tenv_${LATEST_VERSION}_amd64.rpm" && \
    rpm -ivh "tenv_${LATEST_VERSION}_amd64.rpm"

# Install Packer Env
RUN git clone https://github.com/iamhsa/pkenv.git /home/${NORMAL_USER}/.pkenv && \
    PACKER_LATEST_URL=$(curl -sL https://releases.hashicorp.com/packer/index.json | jq -r '.versions[].builds[] | select(.arch=="amd64" and .os=="linux" and (.name|test("alpha|beta|rc")==false)) | .url' | sort -V | tail -1) && \
    PACKER_LATEST_VERSION=$(echo "$PACKER_LATEST_URL" | awk -F '/' '{print $6}' | sed 's/packer_//' | sed 's/_linux_amd64.zip//') && \
    pkenv install ${PACKER_LATEST_VERSION} && \
    pkenv use ${PACKER_LATEST_VERSION}

RUN chown -R ${NORMAL_USER}:${NORMAL_USER} /opt && \
    chown -R ${NORMAL_USER}:${NORMAL_USER} /home/${NORMAL_USER}

RUN dnf -y module enable container-tools:rhel9; dnf -y update; rpm --restore --quiet shadow-utils; \
dnf -y install crun podman podman-docker fuse-overlayfs /etc/containers/storage.conf --exclude container-selinux; \
rm -rf /var/cache /var/log/dnf* /var/log/yum.*

RUN useradd -ms /bin/bash podman; \
echo podman:10000:5000 > /etc/subuid; \
echo podman:10000:5000 > /etc/subgid;

VOLUME /var/lib/containers
RUN mkdir -p /home/podman/.local/share/containers
RUN chown podman:podman -R /home/podman && usermod -aG podman ${NORMAL_USER}
VOLUME /home/podman/.local/share/containers

#https://raw.githubusercontent.com/containers/libpod/master/contrib/podmanimage/stable/containers.conf
ADD containers/rhel/containers.conf /etc/containers/containers.conf
#https://raw.githubusercontent.com/containers/libpod/master/contrib/podmanimage/stable/podman-containers.conf
ADD containers/rhel/podman-containers.conf /home/podman/.config/containers/containers.conf
#https://raw.githubusercontent.com/containers/podman/main/vendor/github.com/containers/storage/storage.conf
ADD containers/rhel/storage.conf /home/podman/.config/containers/storage.conf

#chmod containers.conf and adjust storage.conf to enable Fuse storage.
RUN chmod 644 /etc/containers/containers.conf; sed -i -e 's|^#mount_program|mount_program|g' -e '/additionalimage.*/a "/var/lib/shared",' -e 's|^mountopt[[:space:]]*=.*$|mountopt = "nodev,fsync=0"|g' /etc/containers/storage.conf
RUN mkdir -p /var/lib/shared/overlay-images /var/lib/shared/overlay-layers /var/lib/shared/vfs-images /var/lib/shared/vfs-layers; \
    touch /var/lib/shared/overlay-images/images.lock; \
    touch /var/lib/shared/overlay-layers/layers.lock; \
    touch /var/lib/shared/vfs-images/images.lock; \
    touch /var/lib/shared/vfs-layers/layers.lock

ENV _CONTAINERS_USERNS_CONFIGURED=""

COPY containers/rhel/start.sh  /home/${NORMAL_USER}/start.sh
COPY containers/rhel/env.sh    /home/${NORMAL_USER}/env.sh
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
  pywinrm \
  podman-compose

# Install Azure-CLI as seperate step for cacheing speed
RUN pip3 install --user azure-cli


