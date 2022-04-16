FROM mcr.microsoft.com/windows:20H2

# escape = `

LABEL org.opencontainers.image.source=https://github.com/craigthackerx/azure-devops-agent-containers

COPY tls-fix.ps1 /tls-fix.ps1

ARG NORMAL_USER=ContainerAdministrator
ARG PYTHON3_VERSION=@latest
ARG ACCEPT_EULA=y

ENV NORMAL_USER ${NORMAL_USER}
ENV PYTHON3_VERSION ${PYTHON3_VERSION}
ENV ACCEPT_EULA ${ACCEPT_EULA}

#Use Powershell instead of CMD
SHELL ["powershell", "-Command"]

RUN Set-ExecutionPolicy Unrestricted ; powershell /tls-fix.ps1 ; Remove-Item -Force /tls-fix.ps1

#Set Unrestricted Policy & Install chocolatey
RUN Set-ExecutionPolicy Unrestricted ;  \
    Set-ExecutionPolicy Bypass -Scope Process -Force; iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1')) ; \
    Set-ExecutionPolicy Bypass -Scope Process -Force; iwr -useb get.scoop.sh | iex ; \
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

#Use Powershell Core instead of 5
SHELL ["pwsh", "-Command"]

RUN Set-ExecutionPolicy Unrestricted ; \
    choco install -y \
    python3 --params "/InstallDir:C:\Python" ; \
    pip3 install wheel \
    azure-cli

RUN mkdir C:/azp
WORKDIR C:/azp
COPY start.ps1 /azp/start.ps1

#This can take a while, which is why its a seperate step
RUN Set-ExecutionPolicy Unrestricted ; pwsh -Command Set-PSRepository -Name "PSGallery" -InstallationPolicy Trusted ; pwsh -Command Install-Module -Name Az -Force -AllowClobber -Scope AllUsers -Repository PSGallery

CMD C:/azp/start.ps1