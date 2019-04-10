#Requires -Version 3.0

# Before we do anything else, make sure we have a sufficient .NET version that supports
# System.Net.Http.MultipartFormDataContent for the file upload cmdlets.
# Any version of .NET Core should already work.
if (-not $PSEdition -or $PSEdition -eq 'Desktop') {
    # https://docs.microsoft.com/en-us/dotnet/framework/migration-guide/how-to-determine-which-versions-are-installed#to-check-for-a-minimum-required-net-framework-version-by-querying-the-registry-in-powershell-net-framework-45-and-later
    $netBuild = (Get-ItemProperty "HKLM:SOFTWARE\Microsoft\NET Framework Setup\NDP\v4\Full").Release
    if ($netBuild -ge 378389) { <# 4.5+ - all good #> }
    else {
        # versions prior to 4.5 don't actually have the Release build number in the registry
        # so just display whatever the CLRVersion reports.
        Write-Warning "**********************************************************************"
        Write-Warning "Insufficient .NET version. Found .NET $($PSVersionTable.CLRVersion.ToString())."
        Write-Warning ".NET 4.5 or later is required to ensure proper functionality."
        Write-Warning "**********************************************************************"
    }
}

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
$coldConfig = Import-IBConfig
$script:CurrentHost = $coldConfig.CurrentHost
$script:Config = $coldConfig.Hosts

# Export everything in the public folder
Export-ModuleMember -Function $Public.Basename
