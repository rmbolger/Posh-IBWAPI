#Requires -Version 3.0

# initialize the config container related stuff
$script:CurrentHost = [string]::Empty
if (!$script:Config) { $script:Config = @{} }
if (!$script:Config.$script:CurrentHost) { $script:Config.$script:CurrentHost = @{WAPIHost=$script:CurrentHost} }

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

# Export everything in the public folder
Export-ModuleMember -Function $Public.Basename
