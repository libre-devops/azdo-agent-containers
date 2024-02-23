# configure-path.ps1
# Get the current system PATH
$systemPath = [Environment]::GetEnvironmentVariable("PATH", "Machine")

# Define additional paths for ContainerUser (adjust as necessary)
$additionalPaths = "C:\Users\ContainerUser\scoop\apps;C:\Users\ContainerUser\scoop\apps\nvm\current;C:\Users\ContainerUser\scoop\apps\python\current;C:\Users\ContainerUser\scoop\apps\python\current\Scripts;C:\Users\ContainerUser\scoop\apps\go\current"

# Combine system PATH with additional paths
$newUserPath = "$systemPath;$additionalPaths"

# Set the new combined PATH for the current process (and thus for ContainerUser)
[Environment]::SetEnvironmentVariable("PATH", $newUserPath, "Process")
