<#
  Azure DevOps self-hosted agent bootstrapper (Windows, PowerShell)
  ─────────────────────────────────────────────────────────────────
  • Requires: PowerShell 5.1 + (or pwsh 7 +), .NET 4.7+, Expand-Archive
  • Env vars honoured:
      AZP_URL            – organisation URL  (e.g. https://dev.azure.com/myorg)   [required]
      AZP_TOKEN | AZP_TOKEN_FILE                                                 [required]
      AZP_POOL           – agent-pool name                                       [default: Default]
      AZP_WORK           – work folder                                           [default: _work]
      AZP_AGENT_VERSION  – pin an exact version (skip “latest” lookup)
      TARGETARCH         – win-x64 | win-arm64 | win-x86                         [auto-detected]
      AZP_DIRECTORY      – base folder for agent files                           [default: C:\azp]
#>

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

###############################################################################
# 0. Helper
###############################################################################
function Write-Header {
    param([string]$Text)
    Write-Host "`n$Text`n" -ForegroundColor Cyan
}

###############################################################################
# 1. Mandatory env-vars
###############################################################################
if (-not $Env:AZP_URL) {
    Write-Error 'error: missing AZP_URL environment variable'; exit 1
}

if (-not $Env:AZP_TOKEN_FILE) {
    if (-not $Env:AZP_TOKEN) {
        Write-Error 'error: missing AZP_TOKEN environment variable'; exit 1
    }
    $Env:AZP_TOKEN_FILE = Join-Path ($Env:AZP_DIRECTORY ?? 'C:\azp') '.token'
    $Env:AZP_TOKEN | Out-File -Encoding ascii -NoNewline $Env:AZP_TOKEN_FILE
}
Remove-Item Env:AZP_TOKEN -ErrorAction SilentlyContinue   # don’t leak the token further

###############################################################################
# 2. Paths & architecture
###############################################################################
$BaseDir     = $Env:AZP_DIRECTORY    ?? 'C:\azp'
$AgentRoot   = Join-Path $BaseDir    'agent'
$WorkFolder  = $Env:AZP_WORK         ?? '_work'
$AgentPool   = $Env:AZP_POOL         ?? 'Default'

if (-not (Test-Path $AgentRoot)) { New-Item $AgentRoot -ItemType Directory | Out-Null }

if (-not $Env:TARGETARCH) {
    $Env:TARGETARCH = switch ((Get-CimInstance Win32_OperatingSystem).OSArchitecture) {
        {$_ -match '64'} { 'win-x64' }
        {$_ -match 'ARM64'} { 'win-arm64' }
        default { 'win-x86' }
    }
}

###############################################################################
# 3. Resolve agent version
###############################################################################
if (-not $Env:AZP_AGENT_VERSION) {
    Write-Header 'Resolving latest stable agent version…'
    $latest = Invoke-RestMethod https://api.github.com/repos/microsoft/azure-pipelines-agent/releases |
            Where-Object { -not $_.prerelease } |
            Select-Object -First 1
    $Env:AZP_AGENT_VERSION = $latest.tag_name.TrimStart('v')
    if (-not $Env:AZP_AGENT_VERSION) {
        Write-Error 'error: could not determine agent version from GitHub'; exit 1
    }
}

###############################################################################
# 4. Download & extract
###############################################################################
$zipName      = "vsts-agent-$($Env:TARGETARCH)-$($Env:AZP_AGENT_VERSION).zip"
$downloadUri  = "https://download.agent.dev.azure.com/agent/$($Env:AZP_AGENT_VERSION)/$zipName"
$zipPath      = Join-Path $AgentRoot $zipName

Write-Header "Downloading agent $($Env:AZP_AGENT_VERSION) ($($Env:TARGETARCH))…"
Invoke-WebRequest -Uri $downloadUri -OutFile $zipPath

Write-Header 'Extracting…'
Expand-Archive -Path $zipPath -DestinationPath $AgentRoot -Force
Remove-Item $zipPath

###############################################################################
# 5. Configure
###############################################################################
$agentName = "azdo-agent-$(hostname)-$(Get-Date -Format 'ddMMyyyy')-$(Get-Random -Max 999999)"

$Env:VSO_AGENT_IGNORE = 'AZP_TOKEN,AZP_TOKEN_FILE'
Set-Location $AgentRoot

Write-Header 'Configuring agent…'
& .\config.cmd --unattended `
    --agent  $agentName `
    --url    $Env:AZP_URL `
    --auth   PAT `
    --token  (Get-Content $Env:AZP_TOKEN_FILE) `
    --pool   $AgentPool `
    --work   $WorkFolder `
    --replace `
    --acceptTeeEula

###############################################################################
# 6. Run (and ensure cleanup)
###############################################################################
try {
    Write-Header 'Running agent…'
    & .\run.cmd
}
finally {
    Write-Header 'Cleanup – removing agent…'
    & .\config.cmd remove --unattended `
        --auth PAT `
        --token (Get-Content $Env:AZP_TOKEN_FILE)
}
