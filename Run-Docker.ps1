<#
.SYNOPSIS
    Build (and optionally push) a Docker image – GitHub-Actions-friendly.
#>

param (
    [string]   $DockerFileName   = 'Dockerfile',
    [string]   $DockerImageName  = 'ubuntu-base-docker-container/ubuntu-base',
    [string]   $RegistryUrl      = 'ghcr.io',
    [string]   $RegistryUsername,
    [string]   $RegistryPassword,
    [string]   $ImageOrg,
    [string]   $WorkingDirectory = (Get-Location).Path,
    [string]   $BuildContext     = (Get-Location).Path,
    [string]   $DebugMode        = 'false',   # ← string on purpose (CI inputs)
    [string]   $PushDockerImage  = 'true',
    [string[]] $AdditionalTags   = @('latest', (Get-Date -Format 'yyyy-MM'))
)

#───────────────────────────────────────────────────────────────────────────────
# 0.  Trust PSGallery + install LibreDevOpsHelpers
#───────────────────────────────────────────────────────────────────────────────
try {
    if (Get-Command Set-PSRepository -EA SilentlyContinue) {
        if ((Get-PSRepository -Name PSGallery).InstallationPolicy -ne 'Trusted') {
            Set-PSRepository -Name PSGallery -InstallationPolicy Trusted -EA Stop
        }
    }
    elseif (Get-Command Set-PSResourceRepository -EA SilentlyContinue) {
        Set-PSResourceRepository -Name PSGallery -Trusted -EA Stop
    }
    else {
        throw 'Neither PowerShellGet nor PSResourceGet is available.'
    }
    Write-Host "✅ PSGallery is trusted"
} catch {
    Write-Error "❌ Failed to trust PSGallery: $_"; exit 1
}

if (-not (Get-Module -ListAvailable -Name LibreDevOpsHelpers)) {
    try {
        Install-Module LibreDevOpsHelpers -Repository PSGallery `
            -Scope CurrentUser -Force -AllowClobber -EA Stop
        Write-Host "✅ Installed LibreDevOpsHelpers"
    } catch {
        Write-Error "❌ Could not install LibreDevOpsHelpers: $_"; exit 1
    }
}

Import-Module LibreDevOpsHelpers
_LogMessage INFO "✅ LibreDevOpsHelpers loaded" -InvocationName $MyInvocation.MyCommand.Name

#───────────────────────────────────────────────────────────────────────────────
# 1.  Resolve paths & flags *before* we cd anywhere
#───────────────────────────────────────────────────────────────────────────────
$repoRoot = Convert-Path $WorkingDirectory   # absolute

if ($BuildContext -eq 'github_workspace') { $BuildContext = $repoRoot }
if (-not [IO.Path]::IsPathRooted($BuildContext)) {
    $BuildContext = Join-Path $repoRoot $BuildContext
}
$BuildContext = (Resolve-Path $BuildContext).Path  # canonical

# Dockerfile:
if ([IO.Path]::IsPathRooted($DockerFileName) -or
        $DockerFileName -match '[\\/]'             ) {
    # caller supplied an explicit path (e.g. containers/ubuntu/Dockerfile)
    $DockerfilePath = (Resolve-Path $DockerFileName).Path
} else {
    $DockerfilePath = (Resolve-Path (Join-Path $BuildContext $DockerFileName)).Path
}

if (-not $ImageOrg) { $ImageOrg = $RegistryUsername }
$DockerImageName = "{0}/{1}/{2}" -f $RegistryUrl, $ImageOrg, $DockerImageName

$DebugMode       = ConvertTo-Boolean $DebugMode
$PushDockerImage = ConvertTo-Boolean $PushDockerImage
if ($DebugMode) { $DebugPreference = 'Continue' }

#───────────────────────────────────────────────────────────────────────────────
# 2.  Build helpers (only Build-DockerImage changed)
#───────────────────────────────────────────────────────────────────────────────
function Build-DockerImage {
    [CmdletBinding()] param(
        [Parameter(Mandatory)][string] $DockerfilePath,
        [string] $ContextPath = '.',
        [Parameter(Mandatory)][string] $ImageName
    )

    Write-Host "⏳ Building '$ImageName' from Dockerfile: $DockerfilePath"
    Write-Host "    context: $ContextPath"

    docker build `
        -f $DockerfilePath `
        -t $ImageName `
        $ContextPath | Out-Host

    if ($LASTEXITCODE -ne 0) {
        Write-Error "docker build failed (exit $LASTEXITCODE)"; return $false
    }
    return $true
}

#───────────────────────────────────────────────────────────────────────────────
# 3.  Build / Tag / Push
#───────────────────────────────────────────────────────────────────────────────
Assert-DockerExists

$built = Build-DockerImage `
           -DockerfilePath $DockerfilePath `
           -ContextPath    $BuildContext `
           -ImageName      $DockerImageName
if (-not $built) { Write-Error '❌ docker build failed'; exit 1 }

foreach ($tag in $AdditionalTags) {
    $full = '{0}:{1}' -f $DockerImageName, $tag
    _LogMessage INFO "🏷  Tagging: $full" -InvocationName $MyInvocation.MyCommand.Name
    docker tag $DockerImageName $full
}

if ($PushDockerImage) {
    $tags = $AdditionalTags | ForEach-Object { '{0}:{1}' -f $DockerImageName, $_ }
    if (-not (Push-DockerImage -FullTagNames $tags -RegistryUrl $RegistryUrl -RegistryUsername $RegistryUsername -RegistryPassword $RegistryPassword)) {
        Write-Error '❌ docker push failed'; exit 1
    }
}

_LogMessage INFO '✅ All done.' -InvocationName $MyInvocation.MyCommand.Name
