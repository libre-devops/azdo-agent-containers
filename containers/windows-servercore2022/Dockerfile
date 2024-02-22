FROM mcr.microsoft.com/windows/servercore:ltsc2022

# escape=`

LABEL org.opencontainers.image.title=windows-servercore2022
LABEL org.opencontainers.image.source=https://github.com/libre-devops/azdo-agent-containers

COPY tls-fix.ps1 /tls-fix.ps1

ARG ACCEPT_EULA=y
ENV ACCEPT_EULA ${ACCEPT_EULA}
ENV ChocolateyToolsLocation ${ChocolateyToolsLocation}

# Set args with blank values - these will be over-written with the CLI
ARG AZP_URL=https://dev.azure.com/Example
ARG AZP_TOKEN=ExamplePatToken
ARG AZP_AGENT_NAME=Example
ARG AZP_POOL=Default
ARG AZP_WORK=_work
ARG AZP_DIRECTORY=C:\\Users\\ContainerUser
ARG TARGETARCH=win-x64

# Set the environment with the CLI-passed arguments
ENV AZP_URL=${AZP_URL}
ENV AZP_TOKEN=${AZP_TOKEN}
ENV AZP_POOL=${AZP_POOL}
ENV AZP_WORK=${AZP_WORK}
ENV AZP_DIRECTORY=${AZP_DIRECTORY}

# Corrected PATH to dynamically use the user's home directory for scoop shims
ENV PATH="C:\Windows\system32;C:\Windows;C:\Windows\System32\Wbem;C:\Windows\System32\WindowsPowerShell\v1.0\;C:\Windows\System32\OpenSSH\;C:\ProgramData\chocolatey\bin;C:\Users\ContainerAdministrator\AppData\Local\Microsoft\WindowsApps;C:\Users\ContainerUser\AppData\Local\Microsoft\WindowsApps;C:\Python;C:\Python\Scripts;C:\Program Files\PowerShell\7;C:\Users\ContainerUser;C:\Users\ContainerUser\scoop;C:\Users\ContainerUser\scoop\shims"

# Use Powershell instead of CMD
SHELL ["powershell", "-Command"]

USER ContainerAdministrator

RUN powershell /tls-fix.ps1 ; Remove-Item -Force /tls-fix.ps1

# Set Unrestricted Policy & Install chocolatey
RUN Set-ExecutionPolicy Unrestricted ;  \
    Set-ExecutionPolicy Bypass -Scope Process -Force; iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1')) ; \
    choco install -y \
    sysinternals \
    powershell-core \
    azure-cli

USER ContainerUser

# Use Powershell instead of CMD
SHELL ["pwsh", "-Command"]

RUN Set-ExecutionPolicy Bypass -Scope Process -Force; iwr -useb get.scoop.sh | iex ; \
    scoop install \
    7zip \
    git ; \
    C:\Users\ContainerUser\scoop\apps\git\current\install-file-associations.reg ; \
    scoop bucket add extras ; \
    scoop install \
    curl \
    dark \
    grep \
    jq \
    dotnet-sdk \
    go \
    gawk \
    nano \
    nvm \
    terraform \
    packer \
    openssl \
    lessmsi \
    python \
    rust \
    ruby \
    sed \
    tree \
    which \
    zip ; \
    scoop bucket add java ; \
    scoop install microsoft-jdk ; \
    nvm install lts

# Changed C:/azp to use the AZP_DIRECTORY for the work directory
WORKDIR ${AZP_DIRECTORY}
COPY start.ps1 ${AZP_DIRECTORY}/start.ps1

# This can take a while, which is why its a separate step
RUN pwsh -Command Set-PSRepository -Name "PSGallery" -InstallationPolicy Trusted ; \
    pwsh -Command Install-Module -Name Az -Force -AllowClobber -Scope AllUsers -Repository PSGallery ; \
    pwsh -Command Install-Module -Name Microsoft.Graph -Force -AllowClobber -Scope AllUsers -Repository PSGallery ; \
    pwsh -Command Install-Module -Name Pester -Force -AllowClobber -Scope AllUsers -Repository PSGallery

RUN choco install -y trivy ; \
    pip3 install \
    terraform-compliance \
    checkov \
    black

CMD ${AZP_DIRECTORY}/start.ps1
