#!/usr/bin/env pwsh

$REPO="ghcr.io"

$USER="libre-devops"
$IMAGE_NAME="azdo-agent-winsevercoreltsc2019"
$TAGS = ":latest"

$AZP_URL="https://dev.azure.com/example"
$AZP_TOKEN="example-pat-token"
$AZP_POOL="example-pool"
$AZP_WORK="_work"

docker run -it --rm `
    -e AZP_URL="${AZP_URL}" `
    -e AZP_TOKEN="${AZP_TOKEN}" `
    -e AZP_POOL="${AZP_POOL}" `
    -e AZP_WORK="${AZP_WORK}" `
    "${REPO}/${USER}/${IMAGE_NAME}${TAGS}"