#Requires -Version 3.0

# Set the persistent config file path based on edition/platform
if ('PSEdition' -notin $PSVersionTable.Keys -or $PSVersionTable.PSEdition -eq 'Desktop' -or $IsWindows) {
    $script:ConfigFolder = $env:LOCALAPPDATA
} elseif ($IsLinux) {
    $script:ConfigFolder = Join-Path $env:HOME '.config'
} elseif ($IsMacOs) {
    $script:ConfigFolder = Join-Path $env:HOME 'Library/Preferences'
} else {
    throw "Unrecognized PowerShell platform"
}
$script:ConfigFile = Join-Path $script:ConfigFolder 'posh-ibwapi.json'

# set some string templates we'll be using later
$script:APIBaseTemplate = "https://{0}/wapi/v{1}/"
$script:WAPIDocTemplate = "https://{0}/wapidoc/"

# Get public and private function definition files.
$Public  = @( Get-ChildItem -Path $PSScriptRoot\Public\*.ps1 -ErrorAction SilentlyContinue )
$Private = @( Get-ChildItem -Path $PSScriptRoot\Private\*.ps1 -ErrorAction SilentlyContinue )

# Dot source the files
Foreach($import in @($Public + $Private))
{
    Try { . $import.fullname }
    Catch
    {
        Write-Error -Message "Failed to import function $($import.fullname): $_"
    }
}

# initialize/import the config container related stuff
$coldConfig = Import-IBWAPIConfig
$script:CurrentHost = $coldConfig.CurrentHost
$script:Config = $coldConfig.Hosts

# Export everything in the public folder
Export-ModuleMember -Function $Public.Basename