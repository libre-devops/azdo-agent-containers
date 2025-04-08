# Define the list of environment variables to check
$varCheckList = @(
    'LANG',
    'JAVA_HOME',
    'ANT_HOME',
    'M2_HOME',
    'ANDROID_HOME',
    'GRADLE_HOME',
    'NVM_BIN',
    'NVM_PATH',
    'VSTS_HTTP_PROXY',
    'VSTS_HTTP_PROXY_USERNAME',
    'VSTS_HTTP_PROXY_PASSWORD',
    'LD_LIBRARY_PATH',
    'PERL5LIB',
    'AGENT_TOOLSDIRECTORY'
)

# Initialize variable to hold .env contents
$envContents = ""

# Check if .env file exists, read its contents if it does, otherwise create it
if (Test-Path ".env") {
    $envContents = Get-Content ".env" -Raw
} else {
    New-Item ".env" -ItemType File
}

function Write-Var {
    param (
        [string]$checkVar
    )
    $checkDelim = "${checkVar}="
    if ($envContents -notmatch $checkDelim) {
        $varValue = [System.Environment]::GetEnvironmentVariable($checkVar)
        if ([string]::IsNullOrWhiteSpace($varValue) -eq $false) {
            Add-Content -Path ".env" -Value "${checkVar}=$varValue"
        }
    }
}

# Write current PATH to .path file
$env:PATH | Out-File -FilePath ".path"

# Iterate over the list of variables and write them if necessary
foreach ($varName in $varCheckList) {
    Write-Var -checkVar $varName
}
