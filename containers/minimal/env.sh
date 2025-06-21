#!/usr/bin/env bash

###
varCheckList=(
  LANG JAVA_HOME ANT_HOME M2_HOME ANDROID_HOME GRADLE_HOME
  NVM_BIN NVM_PATH VSTS_HTTP_PROXY VSTS_HTTP_PROXY_USERNAME
  VSTS_HTTP_PROXY_PASSWORD LD_LIBRARY_PATH PERL5LIB AGENT_TOOLSDIRECTORY
)

envFile=".env"
[[ -f $envFile ]] || : >"$envFile"          # create if missing
envContents=$(<"$envFile")

writeVar() {
  local key="$1" keyEq="${1}="
  [[ $envContents == *"$keyEq"* ]] && return        # already in .env

  local val="${!key-}"                              # safe even if unset
  [[ -n $val ]] && printf '%s=%s\n' "$key" "$val" >>"$envFile"
}

# record current PATH separately
printf '%s\n' "$PATH" > .path

for v in "${varCheckList[@]}"; do
  writeVar "$v"
done
