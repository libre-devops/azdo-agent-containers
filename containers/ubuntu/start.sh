#!/usr/bin/env bash
set -e

###############################################################################
# 0.  Unified _logger  (green INFO • yellow WARN • red FAIL)
###############################################################################
ESC="\033"; NC="${ESC}[0m"
GREEN="${ESC}[1;32m"; YELLOW="${ESC}[1;33m"; RED="${ESC}[1;31m"
SCRIPT_NAME="$(basename "$0")"

_logger() {
  local level="${1^^}"; shift
  local ts; ts=$(date '+%H:%M:%S')
  local prefix="${ts} - [${SCRIPT_NAME}]"

  case "$level" in
    INFO)
      printf "${GREEN}INFO : %s %s${NC}\n" "$prefix" "$*"
      ;;
    WARN)
      printf "${YELLOW}WARN : %s %s${NC}\n" "$prefix" "$*"
      ;;
    FAIL|ERROR)
      printf "${RED}FAIL : %s %s${NC}\n"  "$prefix" "$*" >&2
      exit 1
      ;;
    *)
      printf "${YELLOW}WARN : %s unknown level '%s' – %s${NC}\n" "$prefix" "$level" "$*"
      ;;
  esac
}

###############################################################################
# 1.  Mandatory env vars
###############################################################################
[[ -z ${AZP_URL:-}      ]] && _logger FAIL "missing AZP_URL environment variable"
[[ -z ${AZP_TOKEN_FILE:-} && -z ${AZP_TOKEN:-} ]] && _logger FAIL "missing AZP_TOKEN[_FILE]"

if [[ -z ${AZP_TOKEN_FILE:-} ]]; then
  AZP_TOKEN_FILE="$(mktemp)"
  printf '%s' "$AZP_TOKEN" >"$AZP_TOKEN_FILE"
fi
unset AZP_TOKEN

###############################################################################
# 2.  Required tools
###############################################################################
for bin in jq curl tar sed; do
  command -v "$bin" >/dev/null 2>&1 || _logger FAIL "required tool '$bin' not found"
done

###############################################################################
# 3.  Architecture
###############################################################################
if [[ -z ${TARGETARCH:-} ]]; then
  case "$(uname -m)" in
    x86_64)  TARGETARCH="linux-x64"   ;;
    aarch64) TARGETARCH="linux-arm64" ;;
    armv7l)  TARGETARCH="linux-arm"   ;;
    *) _logger FAIL "unsupported architecture $(uname -m)" ;;
  esac
fi
_logger INFO "Architecture            : $TARGETARCH"

###############################################################################
# 4.  Determine agent version
###############################################################################
if [[ -z ${AZP_AGENT_VERSION:-} ]]; then
  _logger INFO "Querying latest stable agent version…"
  AZP_AGENT_VERSION="$(curl -sSL https://api.github.com/repos/microsoft/azure-pipelines-agent/releases \
                       | jq -r '[.[]|select(.prerelease==false)][0].tag_name' \
                       | sed 's/^v//')"
  [[ -z $AZP_AGENT_VERSION || $AZP_AGENT_VERSION == "null" ]] \
    && _logger FAIL "could not determine agent version from GitHub"
fi
_logger INFO "Azure Pipelines agent: $AZP_AGENT_VERSION"

###############################################################################
# 5.  Download & extract
###############################################################################
URL="https://download.agent.dev.azure.com/agent/${AZP_AGENT_VERSION}/vsts-agent-${TARGETARCH}-${AZP_AGENT_VERSION}.tar.gz"
_logger INFO "Downloading agent from $URL"
curl -sSL --progress-bar "$URL" | tar -xz
_logger INFO "Download complete :)"

source ./env.sh   # may set AGENT_OS etc.

###############################################################################
# 6.  Prepare, configure, run
###############################################################################
AZP_AGENT_NAME="azdo-agent-$(hostname)-$(date +%d%m%Y)-$(tr -dc A-Za-z0-9 </dev/urandom | head -c6)"
_logger INFO "Agent name will be: $AZP_AGENT_NAME"
[[ -n ${AZP_WORK:-} ]] && mkdir -p "$AZP_WORK"

cleanup() {
  trap '' EXIT
  if [[ -e ./config.sh ]]; then
    _logger WARN "Removing agent…"
    until ./config.sh remove --unattended --auth PAT --token "$(cat "$AZP_TOKEN_FILE")"; do
      _logger WARN "Retrying removal in 30 s…"
      sleep 30
    done
  fi
}
trap cleanup EXIT INT TERM

export VSO_AGENT_IGNORE="AZP_TOKEN,AZP_TOKEN_FILE"
_logger INFO "Configuring agent…"

./config.sh \
  --unattended \
  --agent "$AZP_AGENT_NAME" \
  --url   "$AZP_URL" \
  --auth  PAT \
  --token "$(cat "$AZP_TOKEN_FILE")" \
  --pool  "${AZP_POOL:-Default}" \
  --work  "${AZP_WORK:-_work}" \
  --replace \
  --acceptTeeEula

_logger INFO "Starting agent – listening for jobs"
chmod +x ./run.sh
./run.sh "$@" &
wait $!
