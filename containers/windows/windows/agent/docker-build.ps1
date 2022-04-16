#!/usr/bin/env pwsh

Set-PSDebug -Trace 1

$REGISTRY = "ghcr.io"
$USER = "craigthackerx"
$IMAGE_NAME = "azure-devops-agent-winseverltsc2022-agent-"
$TAGS = ":latest"
$DOCKERFILE_NAME = "Agent.Dockerfile"

$Start = 1
$End = 1

$AZP_URL = $Env:AZP_URL
$AZP_TOKEN = $Env:AZP_TOKEN
$AZP_POOL = $Env:AZP_POOL
$AZP_WORK = $AZP_WORK

$NORMAL_USER = "ContainerAdministrator"

$START..$END | ForEach-Object {
  docker build `
    --file=$DOCKERFILE_NAME `
    --tag="$REGISTRY/$USER/$IMAGE_NAME$_$TAGS" `
    --build-arg ACCEPT_EULA=y `
    --build-arg NORMAL_USER=$NORMAL_USER `
    --build-arg AZP_URL=$AZP_URL `
    --build-arg AZP_TOKEN=$AZP_TOKEN `
    --build-arg AZP_AGENT_NAME=$(Get-Random) `
    --build-arg AZP_POOL=$AZP_POOL `
    --build-arg AZP_WORK=$AZP_WORK `
    .
}