docker run -it --rm `
   -e AZP_URL=$Env:AZP_URL `
   -e AZP_TOKEN=$Env:AZP_TOKEN `
   -v "//var/run/docker.sock:/var/run/docker.sock" `
   ghcr.io/libre-devops/azdo-agent-containers/ubuntu:latest