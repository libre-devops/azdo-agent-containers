# Azure DevOps Agent Containers

Hello :wave:

In this repo, you will find the various files needed to host a Self-Hosted Azure DevOps Agent inside of a container as
well as examples of a CI/CD workflow.

These images try to follow
the [Microsoft documentation on running self-hosted agent in Docker](https://docs.microsoft.com/en-us/azure/devops/pipelines/agents/docker?view=azure-devops),
but try to add some improvements to this workflow (at least for me), and the repos purpose is to give an overall example
of a workflow on how you can do this. Obviously, being containers, we will all have different usability, so please, feel
free to take the examples and gut the parts you don't need.

There are several projects which attempt to do this, but never in a way that I "_liked_", so this workflow is to
document those short-gaps and try and provide some community support where I can. I am by no means an expert in this,
and this project comes with absolutely no warranty, but should you wish to raise an issue with question, or iterate an
improvement where I've missed something, then please, raise a PR and issue thread to discuss :smile:.

The only thing to note, these containers have no "real" inherit dependencies, in theory, passing `ENV` and/or `ARG`'s
into your container with the `start.sh` and `start.ps1` scripts that I have based from the Microsoft documentation is
enough to get going. But I will try to document what parts are what and why - and my containers are only an example, so
check out the Usage section for more info.

Our containers probably don't follow best practice as I am not really employing any real shell-scripts tricks or layer
optimization, but these work for me. Here is some high level.

## High-level info

- CI/CD with Azure DevOps :rocket:
    - Using easy, readable, script params instead of in-built Steps, Templates & Actions for easy migrations to other
      CI/CDs
- Container registry using GitHub Packages with Github Container Registry :sunglasses:
- Example scripts in Podman, CI/CD pipelines in Podman for Linux and Docker for Windows :whale:
- Linux Images used in the repo:
    - [RedHat 9 Universal Basic Image ](https://catalog.redhat.com/software/container-stacks/detail/5ec53f50ef29fd35586d9a56)
    - [Ubuntu 22.04](https://hub.docker.com/_/ubuntu)

- Windows Image used in the repo:
    - [Windows Server 2022 LTSC](https://hub.docker.com/_/microsoft-windows-server/)

- Agent Name is auto-generated for pool to avoid conflicts, in format:
    - Linux: `azdo-lnx-agent-${{ddmmyyy}-${random_chars}`
    - Windows: `azdo-win-agent-${ddmmyyyy}-${RANDOM_NUMBERS}`

# Quickstart

## Linux

```shell
docker run -it ghcr.io/libre-devops/azdo-agent-containers/ubuntu:latest \
-e AZP_URL="${AZP_URL}" \
-e AZP_TOKEN="${AZP_TOKEN}" \
-e AZP_POOL="${AZP_POOL}" \
-e AZP_WORK="${AZP_WORK}"
```

Or using podman in a startup script

```shell
#!/usr/bin/env bash

REPO="ghcr.io"

USER="libre-devops"
IMAGE_NAME="azdo-agent-containers/rhel"
TAGS=":latest"

AZP_URL="https://dev.azure.com/example"
AZP_TOKEN="example-pat-token"
AZP_POOL="example-pool"
AZP_WORK="_work"

podman run -it \
    -e AZP_URL="${AZP_URL}" \
    -e AZP_TOKEN="${AZP_TOKEN}" \
    -e AZP_POOL="${AZP_POOL}" \
    -e AZP_WORK="${AZP_WORK}" \
    "${REPO}/${USER}/${IMAGE_NAME}${TAGS}"
```

or minimally

```shell
```shell
docker run -it ghcr.io/libre-devops/azdo-agent-containers/ubuntu:latest \
-e AZP_URL="${AZP_URL}" \
-e AZP_TOKEN="${AZP_TOKEN}" \
```

```

## Windows

```powershell
docker run -it ghcr.io/libre-devops/azdo-agent-winservercoreltsc2022:latest \
-e AZP_URL = "${AZP_URL
}" \
-e AZP_TOKEN = "${AZP_TOKEN
}" \
-e AZP_POOL = "${AZP_POOL
}" \
-e AZP_WORK = "${AZP_WORK
}"
```

Startup script

```powershell

#!/usr/bin/env pwsh

$REPO = "ghcr.io"

$USER = "libre-devops"
$IMAGE_NAME = "azdo-agent-winsevercoreltsc2019"
$TAGS = ":latest"

$AZP_URL = "https://dev.azure.com/example"
$AZP_TOKEN = "example-pat-token"
$AZP_POOL = "example-pool"
$AZP_WORK = "_work"

docker run -it --rm `
    -e AZP_URL = "${AZP_URL}" `
    -e AZP_TOKEN = "${AZP_TOKEN}" `
    -e AZP_POOL = "${AZP_POOL}" `
    -e AZP_WORK = "${AZP_WORK}" `
    "${REPO}/${USER}/${IMAGE_NAME}${TAGS}"
```

## Podman-in-Podman

Looking to run Podman containers within a container? The Linux containers in this repo support it!. To do this however,
you do need to run the container in `--priviledged` mode. You can still run it as a standard user. Here is an example on
how to run interactively

```shell
#!/usr/bin/env bash

REPO="ghcr.io"

USER="libre-devops"
IMAGE_NAME="azdo-agent-rhel"
TAGS=":latest"

AZP_URL="https://dev.azure.com/example"
AZP_TOKEN="example-pat-token"
AZP_POOL="example-pool"
AZP_WORK="_work"

podman run -it --rm --privileged -u root \
    -e AZP_URL="${AZP_URL}" \
    -e AZP_TOKEN="${AZP_TOKEN}" \
    -e AZP_POOL="${AZP_POOL}" \
    -e AZP_WORK="${AZP_WORK}" \
    "${REPO}/${USER}/${IMAGE_NAME}${TAGS} \
    bash"
```

And then inside the container:

```shell
root@7483265642f0:/azp# podman run -it ubuntu:latest
Resolved "ubuntu" as an alias (/etc/containers/registries.conf.d/000-shortnames.conf)
Trying to pull docker.io/library/ubuntu:latest...
Getting image source signatures
Copying blob e0b25ef51634 done
Copying config 825d55fb63 done
Writing manifest to image destination
Storing signatures
root@7483265642f0:/# ls
bin  boot  dev  etc  home  lib  lib32  lib64  libx32  media  mnt  opt  proc  root  run  sbin  srv  sys  tmp  usr  var
```

Alternatively, you can fork the repo and edit the pipelines to include your secrets as build args into the template!

## Info

- On Linux:
    - Various packages and updates needed.
    - Python - Latest version with argument at pipeline level for roll-back options - This is for Azure-CLI which I wish
      to be part of ALL of my agents
    - Azure-CLI - Installed via global pip3
    - PowerShell 7 - With all Azure modules downloaded (these are around 2GB in size, which is why its part of the base)
    - The script which will execute on `CMD` in the container, which will fetch the latest Azure Pipelines agent on
      execution
- On Windows:
    - Chocolatey and Scoop installed
    - Python - Latest version from chocolatey
    - Azure-CLI - Latest version from chocolatey
    - Git - Latest from chocolatey (and will also install Bash)
    - 7-Zip
    - Scoop "extras" bucket

Some others notes:

We do not own or give any explicit license agreements which may be contained with the software in these images, but have
given images for examples and published them to allow experiments :scientist:. The images are as follows:

- Image - Standard Image with Python, PowerShell and Azure-CLI, examples in this
  repo:  `rhel`, `ubuntu`, `winseverltsc2019`, `winseverltsc2022`
- All images are tagged as latest and available in `ghcr.io/libre-devops`
