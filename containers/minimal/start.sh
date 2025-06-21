#!/usr/bin/env bash
set -euo pipefail

#
# Azure DevOps self-hosted agent bootstrapper
#   • Requires: bash, curl, jq, tar, sed
#   • Environment variables honoured:
#       AZP_URL           (org URL, e.g. https://dev.azure.com/myorg)   – required
#       AZP_TOKEN | AZP_TOKEN_FILE                                      – required
#       AZP_POOL          (agent pool name)                             – default: Default
#       AZP_WORK          (work folder)                                 – default: _work
#       AZP_AGENT_VERSION (override exact agent version)
#       TARGETARCH        (linux-x64 | linux-arm64 | linux-arm)         – auto-detected if unset
#

###############################################################################
# 0. Mandatory environment variables
###############################################################################
if [[ -z ${AZP_URL:-} ]]; then
  printf >&2 "error: missing AZP_URL environment variable\n"
  exit 1
fi

# Handle PAT token input
if [[ -z ${AZP_TOKEN_FILE:-} ]]; then
  if [[ -z ${AZP_TOKEN:-} ]]; then
    printf >&2 "error: missing AZP_TOKEN environment variable\n"
    exit 1
  fi
  AZP_TOKEN_FILE="$(mktemp)"
  printf '%s' "$AZP_TOKEN" >"$AZP_TOKEN_FILE"
fi
unset AZP_TOKEN   # never pass the token further via env

###############################################################################
# 1. Required tools check
###############################################################################
for bin in jq curl tar sed; do
  command -v "$bin" >/dev/null 2>&1 || {
    printf >&2 "error: missing required tool '%s'\n" "$bin"
    exit 1
  }
done

###############################################################################
# 2. Architecture-specific variables
###############################################################################
if [[ -z ${TARGETARCH:-} ]]; then
  case "$(uname -m)" in
    x86_64)  TARGETARCH="linux-x64"  ;;
    aarch64) TARGETARCH="linux-arm64" ;;
    armv7l)  TARGETARCH="linux-arm"   ;;
    *) printf >&2 "error: unsupported architecture %s\n" "$(uname -m)"; exit 1 ;;
  esac
fi

###############################################################################
# 3. Resolve agent version
###############################################################################
if [[ -z ${AZP_AGENT_VERSION:-} ]]; then
  printf 'Finding latest stable agent version…\n'
  AZP_AGENT_VERSION="$(
    curl -sSL https://api.github.com/repos/microsoft/azure-pipelines-agent/releases \
    | jq -r '[ .[] | select(.prerelease==false) ][0].tag_name' \
    | sed 's/^v//'
  )"
  if [[ -z $AZP_AGENT_VERSION || $AZP_AGENT_VERSION == "null" ]]; then
    printf >&2 "error: could not determine agent version from GitHub\n"
    exit 1
  fi
fi

###############################################################################
# 4. Build download URL & fetch
###############################################################################
DOWNLOAD_URL="https://download.agent.dev.azure.com/agent/${AZP_AGENT_VERSION}/vsts-agent-${TARGETARCH}-${AZP_AGENT_VERSION}.tar.gz"
printf 'Downloading Azure Pipelines agent %s (%s)…\n' "$AZP_AGENT_VERSION" "$TARGETARCH"
curl -sSL "$DOWNLOAD_URL" | tar -xz

# shellcheck disable=SC1091
source ./env.sh   # exposes AGENT_OS, etc.

###############################################################################
# 5. Pre-flight: name, work folder, cleanup trap
###############################################################################
AZP_AGENT_NAME="azdo-agent-$(hostname)-$(date +%d%m%Y)-$(tr -dc A-Za-z0-9 </dev/urandom | head -c6)"

[[ -n ${AZP_WORK:-} ]] && mkdir -p "$AZP_WORK"

cleanup() {
  trap '' EXIT
  if [[ -e ./config.sh ]]; then
    printf '\nRemoving agent…\n'
    while ! ./config.sh remove --unattended --auth PAT --token "$(cat "$AZP_TOKEN_FILE")"; do
      printf 'Retrying in 30 seconds…\n'
      sleep 30
    done
  fi
}
trap cleanup EXIT INT TERM

###############################################################################
# 6. Configure the agent
###############################################################################
export VSO_AGENT_IGNORE="AZP_TOKEN,AZP_TOKEN_FILE"

./config.sh \
  --unattended \
  --agent   "${AZP_AGENT_NAME}" \
  --url     "${AZP_URL}" \
  --auth    PAT \
  --token   "$(cat "$AZP_TOKEN_FILE")" \
  --pool    "${AZP_POOL:-Default}" \
  --work    "${AZP_WORK:-_work}" \
  --replace \
  --acceptTeeEula

###############################################################################
# 7. Run
###############################################################################
chmod +x ./run.sh
./run.sh "$@" &
wait $!
