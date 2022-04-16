#!/usr/bin/env bash

REPO="ghcr.io"

USER="libre-devops"
IMAGE_NAME="azdo-agent-rhel"
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