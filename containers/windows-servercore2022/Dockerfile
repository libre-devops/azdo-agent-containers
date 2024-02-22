FROM mcr.microsoft.com/windows/servercore:ltsc2022

# escape = `

LABEL org.opencontainers.image.title=windows-servercore2022
LABEL org.opencontainers.image.source=https://github.com/libre-devops/azdo-agent-containers

COPY tls-fix.ps1 /tls-fix.ps1

ARG NORMAL_USER=ContainerAdministrator
ARG PYTHON3_VERSION=@latest
ARG ACCEPT_EULA=y

ENV NORMAL_USER ${NORMAL_USER}
ENV PYTHON3_VERSION ${PYTHON3_VERSION}
ENV ACCEPT_EULA ${ACCEPT_EULA}

#Set args with blank values - these will be over-written with the CLI
ARG AZP_URL=https://dev.azure.com/Example
ARG AZP_TOKEN=ExamplePatToken
ARG AZP_AGENT_NAME=Example
ARG AZP_POOL=Default
ARG AZP_WORK=_work
ARG AZP_DIRECTORY="C:\Users"\\${NORMAL_USER}"
ARG ACCEPT_EULA=y
ARG TARGETARCH="win-x64"

#Set the environment with the CLI-passed arguements
ENV AZP_URL ${AZP_URL}
ENV AZP_TOKEN ${AZP_TOKEN}
ENV AZP_POOL ${AZP_POOL}
ENV AZP_WORK ${AZP_WORK}

#Use Powershell instead of CMD
SHELL ["powershell", "-Command"]

RUN powershell /tls-fix.ps1 ; Remove-Item -Force /tls-fix.ps1

#Set Unrestricted Policy & Install chocolatey
RUN Set-ExecutionPolicy Unrestricted ;  \
    Set-ExecutionPolicy Bypass -Scope Process -Force; iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1')) ; \
    Set-ExecutionPolicy Bypass -Scope Process -Force; iwr -useb get.scoop.sh -outfile 'install.ps1'; .\install.ps1 -RunAsAdmin; Remove-Item -force install.ps1 ; \
    choco install -y \
    powershell-core  \
    azure-cli ; \
    scoop install \
    7zip \
    git ; \
    scoop bucket add extras ; \
    scoop install \
    curl \
    dark \
    lessmsi \
    jq \
    sed \
    which \
    zip

ENV PATH "C:\Windows\system32;C:\Windows;C:\Windows\System32\Wbem;C:\Windows\System32\WindowsPowerShell\v1.0\;C:\Windows\System32\OpenSSH\;C:\Users\ContainerAdministrator\AppData\Local\Microsoft\WindowsApps;C:\Python;C:\Python\Scripts;C:\ProgramData\chocolatey\bin;C:\Users"\\${NORMAL_USER}"\scoop\shims;C:\Program Files\PowerShell\7"

RUN choco install -y \
    python3 --params "/InstallDir:C:\Python" ; \
    pip3 install wheel \
    azure-cli

RUN mkdir C:/azp
WORKDIR C:/azp
COPY start.ps1 /azp/start.ps1

#This can take a while, which is why its a seperate step
RUN pwsh -Command Set-PSRepository -Name "PSGallery" -InstallationPolicy Trusted ; pwsh -Command Install-Module -Name Az -Force -AllowClobber -Scope AllUsers -Repository PSGallery

RUN scoop install terraform packer ; \
    choco install -y trivy ; \
    pip3 install \
    terraform-compliance \
    checkov \
    black

#Use Powershell Core instead of 5
SHELL ["pwsh", "-Command"]

CMD C:/Users/${NORMAL_USER}/start.ps1
