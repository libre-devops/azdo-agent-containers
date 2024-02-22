function Print-Header {
    param (
        [string]$message
    )
    Write-Host $message -ForegroundColor Cyan
}

$AZP_AGENT_NAME = "azdo-winsrvcr2022-agent-$(Get-Date -Format 'ddMMyyyy')-$(Get-Random -Maximum 9999999999)"
$USER = "microsoft"
$REPO = "azure-pipelines-agent"
$OS = "windows"
$ARCH = "x64"
$PACKAGE = "zip"

# Check for required tools
if (-not(Get-Command jq -ErrorAction SilentlyContinue) -or -not(Get-Command curl -ErrorAction SilentlyContinue) -or -not(Get-Command sed -ErrorAction SilentlyContinue)) {
    Write-Error "You do not have the needed packages (jq, curl, sed) to run the script, please install them"
    exit 1
}

Print-Header "0. Checking jq, curl, and sed are installed..."

$azdoLatestAgentVersion = curl --silent "https://api.github.com/repos/$USER/$REPO/releases/latest" | jq -r .tag_name
$strippedTagAzDoAgentVersion = $azdoLatestAgentVersion -replace 'v', ''
$AZP_AGENTPACKAGE_URL = "https://vstsagentpackage.azureedge.net/agent/$strippedTagAzDoAgentVersion/vsts-agent-$OS-$ARCH-$strippedTagAzDoAgentVersion.$PACKAGE"

if (-not $Env:AZP_URL) {
    Write-Error "error: missing AZP_URL environment variable"
    exit 1
}

if (-not $Env:AZP_TOKEN_FILE) {
    if (-not $Env:AZP_TOKEN) {
        Write-Error "error: missing AZP_TOKEN environment variable"
        exit 1
    }
    $AZP_TOKEN_FILE = "${Env:AZP_DIRECTORY}\.token"
    $Env:AZP_TOKEN | Out-File -FilePath $AZP_TOKEN_FILE
}

Remove-Item Env:AZP_TOKEN -ErrorAction Ignore

if ($Env:AZP_WORK) {
    New-Item -Path $Env:AZP_WORK -ItemType Directory -Force | Out-Null
}

Remove-Item "${Env:AZP_DIRECTORY}\agent" -Recurse -ErrorAction Ignore
New-Item "${Env:AZP_DIRECTORY}\agent" -ItemType Directory | Out-Null

Set-Location "${Env:AZP_DIRECTORY}\agent"

$Env:AGENT_ALLOW_RUNASROOT = "1"

function Cleanup {
    Print-Header "Cleanup. Removing Azure Pipelines agent..."
    .\config.cmd remove --unattended --auth PAT --token (Get-Content $Env:AZP_TOKEN_FILE)
}

$Env:VSO_AGENT_IGNORE = "AZP_TOKEN,AZP_TOKEN_FILE"

Print-Header "1. Determining matching Azure Pipelines agent..."

$base64AuthInfo = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(":$(Get-Content $Env:AZP_TOKEN_FILE)"))
$AZP_AGENT_RESPONSE = Invoke-RestMethod -Headers @{Authorization=("Basic $base64AuthInfo")} -Uri "$($Env:AZP_URL)/_apis/distributedtask/packages/agent?platform=win-x64"

if ($AZP_AGENT_RESPONSE) {
    $AZP_AGENTPACKAGE_URL = $AZP_AGENT_RESPONSE.value | Sort-Object -Property version -Descending | Select-Object -First 1 -ExpandProperty downloadUrl
}

if (-not $AZP_AGENTPACKAGE_URL) {
    Write-Error "error: could not determine a matching Azure Pipelines agent - check that account '$Env:AZP_URL' is correct and the token is valid for that account"
    exit 1
}

Print-Header "2. Downloading and installing Azure Pipelines agent..."

$wc = New-Object System.Net.WebClient
$wc.DownloadFile($AZP_AGENTPACKAGE_URL, "${Env:AZP_DIRECTORY}\agent\agent.zip")
Expand-Archive -Path "${Env:AZP_DIRECTORY}\agent\agent.zip" -DestinationPath "${Env:AZP_DIRECTORY}\agent"

Print-Header "3. Configuring Azure Pipelines agent..."

.\config.cmd --unattended `
  --agent $AZP_AGENT_NAME `
  --url $Env:AZP_URL `
  --auth PAT `
  --token (Get-Content $Env:AZP_TOKEN_FILE) `
  --pool "${Env:AZP_POOL}" `
  --work "${Env:AZP_WORK}" `
  --replace `
  --acceptTeeEula

Print-Header "4. Running Azure Pipelines agent..."

try {
    .\run.cmd
}
finally {
    Cleanup
}
