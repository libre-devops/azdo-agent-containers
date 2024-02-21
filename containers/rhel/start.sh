#!/usr/bin/env bash

set -e

print_header() {
  local lightcyan='\033[1;36m'
  local nocolor='\033[0m'
  echo -e "${lightcyan}$1${nocolor}"
}

AZP_AGENT_NAME="azdo-agent-lnx-$(date +'%d%m%Y')-$(head /dev/urandom | tr -dc A-Za-z0-9 | head -c10)"

USER="microsoft"
REPO="azure-pipelines-agent"
OS="linux"
ARCH="x64"
PACKAGE="tar.gz"

if [ "$(command -v jq)" ] && [ "$(command -v curl)" ] && [ "$(command -v sed)" ]; then
  print_header "0. Checking jq, curl and sed are installed..."

else
  echo "You do not have the needed packages to run the script, please install them" && exit 1

fi

azdoLatestAgentVersion="$(curl --silent "https://api.github.com/repos/${USER}/${REPO}/releases/latest" | jq -r .tag_name)" &&
  strippedTagAzDoAgentVersion="${azdoLatestAgentVersion//v/}" &&
  AZP_AGENTPACKAGE_URL="https://vstsagentpackage.azureedge.net/agent/${strippedTagAzDoAgentVersion}/vsts-agent-${OS}-${ARCH}-${strippedTagAzDoAgentVersion}.${PACKAGE}"

if [ -z "${AZP_URL}" ]; then
  echo 1>&2 "error: missing AZP_URL environment variable"
  exit 1
fi

if [ -z "${AZP_TOKEN_FILE}" ]; then
  if [ -z "${AZP_TOKEN}" ]; then
    echo 1>&2 "error: missing AZP_TOKEN environment variable"
    exit 1
  fi

  AZP_TOKEN_FILE="${AZP_DIRECTORY}/.token"
  echo -n "${AZP_TOKEN}" >"${AZP_TOKEN_FILE}"
fi

unset AZP_TOKEN

if [ -n "${AZP_WORK}" ]; then
  mkdir -p "${AZP_WORK}"
fi

rm -rf "${AZP_DIRECTORY}/agent"
mkdir "${AZP_DIRECTORY}/agent"
cd "${AZP_DIRECTORY}/agent"

export AGENT_ALLOW_RUNASROOT="1"

cleanup() {
  if [ -e config.sh ]; then
    print_header "Cleanup. Removing Azure Pipelines agent..."

    ./config.sh remove --unattended \
      --auth PAT \
      --token "$(cat "${AZP_TOKEN_FILE}")"
  fi
}

# Let the agent ignore the token env variables
export VSO_AGENT_IGNORE=AZP_TOKEN,AZP_TOKEN_FILE

print_header "1. Determining matching Azure Pipelines agent..."

AZP_AGENT_RESPONSE=$(curl -LsS \
  -u user:"$(cat "${AZP_TOKEN_FILE}")" \
  -H 'Accept:application/json;api-version=3.0-preview' \
  "${AZP_URL}/_apis/distributedtask/packages/agent?platform=linux-x64")

if echo "${AZP_AGENT_RESPONSE}" | jq . >/dev/null 2>&1; then
  AZP_AGENTPACKAGE_URL="$(echo "${AZP_AGENT_RESPONSE}" |
    jq -r '.value | map([.version.major,.version.minor,.version.patch,.downloadUrl]) | sort | .[length-1] | .[3]')"
fi

if [ -z "${AZP_AGENTPACKAGE_URL}" ] || [ "${AZP_AGENTPACKAGE_URL}" == "null" ]; then
  echo 1>&2 "error: could not determine a matching Azure Pipelines agent - check that account '$AZP_URL' is correct and the token is valid for that account"
  exit 1
fi

print_header "2. Downloading and installing Azure Pipelines agent..."

curl -LsS "${AZP_AGENTPACKAGE_URL}" | tar -xz &
wait $!


print_header "3. Sourcing env.sh"

source ./env.sh

print_header "4. Configuring Azure Pipelines agent..."

./config.sh --unattended \
  --agent "${AZP_AGENT_NAME:-$(hostname)}" \
  --url "${AZP_URL}" \
  --auth PAT \
  --token "$(cat "${AZP_TOKEN_FILE}")" \
  --pool "${AZP_POOL}" \
  --work "${AZP_WORK:-_work}" \
  --replace \
  --acceptTeeEula &
wait $!

print_header "5. Running Azure Pipelines agent..."

trap 'cleanup; exit 130' INT
trap 'cleanup; exit 143' TERM

# To be aware of TERM and INT signals call run.sh
# Running it with the --once flag at the end will shut down the agent after the build is executed
./run.sh &
wait $!
