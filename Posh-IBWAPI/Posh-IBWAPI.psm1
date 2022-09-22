#Requires -Version 5.1

# For Desktop editions, make sure we have a sufficient .NET version that supports
# System.Net.Http.MultipartFormDataContent for the file upload cmdlets.
if (-not $PSEdition -or $PSEdition -eq 'Desktop') {
    # https://docs.microsoft.com/en-us/dotnet/framework/migration-guide/how-to-determine-which-versions-are-installed#to-check-for-a-minimum-required-net-framework-version-by-querying-the-registry-in-powershell-net-framework-45-and-later
    $netBuild = (Get-ItemProperty "HKLM:SOFTWARE\Microsoft\NET Framework Setup\NDP\v4\Full").Release
    if ($netBuild -ge 379893) { <# 4.5.2+ - all good #> }
    else {
        if     ($netBuild -ge 378675) { $netVer = '4.5.1' }
        elseif ($netBuild -ge 378389) { $netVer = '4.5' }
        Write-Warning "**********************************************************************"
        Write-Warning "Insufficient .NET version. Found .NET $netVer (build $netBuild)."
        Write-Warning ".NET 4.5.2 or later is required to ensure proper functionality."
        Write-Warning "**********************************************************************"
    }
}

# For Core edition, try to enforce 7.0 or later.
if ($PSEdition -eq 'Core' -and $PSVersionTable.PSVersion -lt [version]'7.0') {
    Write-Warning "**********************************************************************"
    Write-Warning "Posh-IBWAPI no longer supports PowerShell 6.x. Found $($PSVersionTable.PSVersion)."
    Write-Warning "PowerShell 7.0 or later is required to ensure proper functionality."
    Write-Warning "**********************************************************************"
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
foreach ($import in @($Public + $Private))
{
    try { . $import.fullname }
    catch {
        Write-Error -Message "Failed to import function $($import.fullname): $_"
    }
}

Register-ArgCompleters

# initialize/import the config
Import-IBConfig
