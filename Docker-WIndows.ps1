docker run -it --rm `
    -e AZP_URL `
    -e AZP_TOKEN `
    -v "//var/run/docker.sock:/var/run/docker.sock" `
    ghcr.io/libre-devops/azdo-agent-containers/ubuntu:latest `
    -NoLogo -NoProfile -Command {
    "AZP_URL   = $env:AZP_URL"
    "AZP_TOKEN = $env:AZP_TOKEN"
}