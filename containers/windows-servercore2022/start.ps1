$AZP_DIRECTORY = $Env:AZP_DIRECTORY

function Print-Header($header)
{
    Write-Host "`n${header}`n" -ForegroundColor Cyan
}

if (-not(Test-Path Env:AZP_URL))
{
    Write-Error "error: missing AZP_URL environment variable"
    exit 1
}

if (-not(Test-Path Env:AZP_TOKEN_FILE))
{
    if (-not(Test-Path Env:AZP_TOKEN))
    {
        Write-Error "error: missing AZP_TOKEN environment variable"
        exit 1
    }

    $Env:AZP_TOKEN_FILE = "${AZP_DIRECTORY}\.token"
    $Env:AZP_TOKEN | Out-File -FilePath $Env:AZP_TOKEN_FILE
}

$AZP_AGENT_NAME = "azdo-winsrvcr2022-agent-$( Get-Date -Format 'ddMMyyyy' )-$( Get-Random -Maximum 9999999999 )"

Remove-Item Env:AZP_TOKEN

if ((Test-Path Env:AZP_WORK) -and -not(Test-Path $Env:AZP_WORK))
{
    New-Item $Env:AZP_WORK -ItemType directory | Out-Null
}

New-Item "${AZP_DIRECTORY}\agent" -ItemType directory | Out-Null

# Let the agent ignore the token env variables
$Env:VSO_AGENT_IGNORE = "AZP_TOKEN,AZP_TOKEN_FILE"

# Check for required tools
if (-not(Get-Command jq -ErrorAction SilentlyContinue) -or -not(Get-Command curl -ErrorAction SilentlyContinue) -or -not(Get-Command sed -ErrorAction SilentlyContinue))
{
    Write-Error "You do not have the needed packages (jq, curl, sed) to run the script, please install them"
    exit 1
}


Set-Location agent

Print-Header "1. Determining matching Azure Pipelines agent..."

$base64AuthInfo = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(":$( Get-Content ${Env:AZP_TOKEN_FILE} )"))
$package = Invoke-RestMethod -Headers @{ Authorization = ("Basic $base64AuthInfo") } "$( ${Env:AZP_URL} )/_apis/distributedtask/packages/agent?platform=win-x64&`$top=1"
$packageUrl = $package[0].Value.downloadUrl

Write-Host $packageUrl

Print-Header "2. Downloading and installing Azure Pipelines agent..."
$CurrentWd = $( Get-Location ).Path
$AgentPath = Join-Path -Path $CurrentWd -ChildPath "agent.zip"
$wc = New-Object System.Net.WebClient
$wc.DownloadFile($packageUrl, $AgentPath)

Expand-Archive -Path $AgentPath -DestinationPath "C:\agent"
$configCmdPath = Join-Path -Path "C:\agent" -ChildPath "config.cmd"

try
{
    Print-Header "3. Configuring Azure Pipelines agent..."

    pwsh -Command $configCmdPath --unattended `
    --agent "$( if (Test-Path Env:AZP_AGENT_NAME)
    {
        ${Env:AZP_AGENT_NAME}
    }
    else
    {
        hostname
    } )" `
    --url "$( ${Env:AZP_URL} )" `
    --auth PAT `
    --token "$( Get-Content ${Env:AZP_TOKEN_FILE} )" `
    --pool "$( if (Test-Path Env:AZP_POOL)
    {
        ${Env:AZP_POOL}
    }
    else
    {
        'Default'
    } )" `
    --work "$( if (Test-Path Env:AZP_WORK)
    {
        ${Env:AZP_WORK}
    }
    else
    {
        '_work'
    } )" `
    --replace

    Print-Header "4. Running Azure Pipelines agent..."

    .\run.cmd
}
finally
{
    Print-Header "Cleanup. Removing Azure Pipelines agent..."

    pwsh -Command $configCmdPath remove --unattended `
    --auth PAT `
    --token "$( Get-Content ${Env:AZP_TOKEN_FILE} )"
}
