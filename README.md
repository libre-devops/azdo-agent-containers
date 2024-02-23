# Azure DevOps Agent Containers

Hello :wave:

In this repo, you will find the various files needed to host a Self-Hosted Azure DevOps Agent inside a container as
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
- Container registry using GitHub Packages with GitHub Container Registry :sunglasses:
- Example scripts in Podman, CI/CD pipelines in Podman for Linux and Docker for Windows :whale:
- Linux Images used in the repo:
    - [RedHat 9 Universal Basic Image ](https://catalog.redhat.com/software/container-stacks/detail/5ec53f50ef29fd35586d9a56)
    - [Ubuntu 22.04](https://hub.docker.com/_/ubuntu)
    - [Alpine](https://hub.docker.com/_/alpine)

- Windows Image used in the repo:
    - [Windows Server 2022 LTSC](https://hub.docker.com/_/microsoft-windows-server/)

- Agent Name is auto-generated for pool to avoid conflicts, in format:
    - Linux: `azdo-${OS-NAME}-agent-${{ddmmyyy}-${random_chars}`
    - Windows: `azdo-${OS-NAME}-agent-${ddmmyyyy}-${RANDOM_NUMBERS}`

# Quickstart

## Linux

```shell
docker run -it ghcr.io/libre-devops/azdo-agent-containers/ubuntu:latest \
-e AZP_URL="${AZP_URL}" \
-e AZP_TOKEN="${AZP_TOKEN}" \
-e AZP_POOL="${AZP_POOL}" \
-e AZP_WORK="${AZP_WORK}"
```

or minimally

```shell
docker run -it \
-e AZP_URL="${AZP_URL}" \
-e AZP_TOKEN="${AZP_TOKEN}" \
ghcr.io/libre-devops/azdo-agent-containers/ubuntu:latest

```

## Windows

```powershell
docker run -it `
-e AZP_URL = "${AZP_URL}" `
-e AZP_TOKEN = "${AZP_TOKEN}" `
-e AZP_POOL = "${AZP_POOL}" `
-e AZP_WORK = "${AZP_WORK}" `
ghcr.io/libre-devops/azdo-agent-containers/windows-servercore2022:latest 
```

## Podman-in-Podman

Looking to run Podman containers within a container? The `rhel` and `default` containers in this repo support it!. To do this however,
you do need to run the container in `--priviledged` mode and run the container user as root. You can still run the container itself as a standard user, it's just the inside user that will need to be root. Here is an example on
how to run:

```shell
podman run -it --privileged -u root \
-e AZP_URL="${AZP_URL}" \
-e AZP_TOKEN="${AZP_TOKEN}" \
-e AGENT_ALLOW_RUNASROOT=1 \
ghcr.io/libre-devops/azdo-agent-containers/default:latest
```

```shell
podman run -it --privileged -u root \
-e AZP_URL="${AZP_URL}" \
-e AZP_TOKEN="${AZP_TOKEN}" \
-e AGENT_ALLOW_RUNASROOT=1 \
ghcr.io/libre-devops/azdo-agent-containers/rhel:latest
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

## Run Azure DevOps agent as root
```shell
podman run -it --privileged -u root \
    -e AZP_URL="${AZP_URL}" \
    -e AZP_TOKEN="${AZP_TOKEN}" \
    -e AGENT_ALLOW_RUNASROOT=1 \
    ghcr.io/libre-devops/azdo-agent-containers/rhel:latest
```

## As Kubernetes

### Create a kube-azdo-creds.yaml
```yaml
apiVersion: v1
kind: Secret
metadata:
  name: azdo-agents-creds
type: Opaque
data:
  azdo-token: <base64-encoded-token-without-newline>
  azdo-url: <base64-encoded-url-without-newline>
```
### Run kubectl
```shell
kubectl apply -f azdo-agents-creds.yaml && \
kubectl apply -f azdo-agents-deployment.yaml
```

## As Kubernetes in Podman

Run the helper script

```shell
# Ensure the script stops if an error occurs
set -e

# Pull the necessary pause image
podman pull k8s.gcr.io/pause:3.5

podman kube play kube-azdo-creds.yaml && \
podman play kube podman-kube-deployment.yaml
```

Alternatively, you can fork the repo and edit the pipelines to include your secrets as build args into the template!

We do not own or give any explicit license agreements which may be contained with the software in these images, but have
given images for examples and published them to allow experiments :scientist:. The images are as follows:

- All images are tagged as latest and YYYY-MM and available in `ghcr.io/libre-devops/azdo-agent-containers/${name}`
- For legacy reasons, the image `ghcr.io/libre-devops/azdo-agent-rhel:latest` (also tagged `ghcr.io/libre-devops/azdo-agent-rhel:april-2023`) is kept for legacy users. Please use an alternative image for updates
