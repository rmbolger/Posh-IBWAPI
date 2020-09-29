function Import-IBConfig
{
    [CmdletBinding()]
    param()

    # initialize empty profiles
    Set-CurrentProfile ([string]::Empty)
    $profiles = $script:Profiles = @{}

    # make sure session and schema caches are initialized
    if (-not $script:Sessions) {
        $script:Sessions = @{}
    }
    if (-not $script:Schemas) {
        $script:Schemas = @{}
    }

    # return early if there's no file to load
    $configFile = Get-ConfigFile
    if (-not (Test-Path $configFile -PathType Leaf)) { return }

    # load the json content on disk to a pscustomobject
    try {
        $json = Get-Content $configFile -Encoding UTF8 -Raw | ConvertFrom-Json
    } catch {
        Write-Warning "Unable to parse existing config file: $($_.Exception.Message)"
        return
    }

    $propNames = @($json.PSObject.Properties.Name)
    $backup1x = $false

    # grab the current profile
    if ('CurrentProfile' -in $propNames) {
        Set-CurrentProfile $json.CurrentProfile
    } elseif ('CurrentHost' -in $propNames) {
        # allow for legacy 1.x config import
        Set-CurrentProfile $json.CurrentHost
        $backup1x = $true
    }

    # load the rest of the profiles
    if ('Profiles' -in $propNames) {
        $json.Profiles.PSObject.Properties.Name | ForEach-Object {
            $profiles.$_ = @{
                WAPIHost    = $json.Profiles.$_.WAPIHost
                WAPIVersion = $json.Profiles.$_.WAPIVersion
                Credential  = $null
                SkipCertificateCheck = $false
            }
            if ('Credential' -in $json.Profiles.$_.PSObject.Properties.Name) {
                $profiles.$_.Credential = (Import-IBCred $json.Profiles.$_.Credential $_)
            }
            if ($json.Profiles.$_.SkipCertificateCheck) {
                $profiles.$_.SkipCertificateCheck = $true
            }
        }
    } elseif ('Hosts' -in $propNames) {
        # allow for legacy 1.x config import
        $json.Hosts.PSObject.Properties.Name | ForEach-Object {
            $profiles.$_ = @{
                WAPIHost    = $json.Hosts.$_.WAPIHost
                WAPIVersion = $json.Hosts.$_.WAPIVersion
                Credential  = $null
                SkipCertificateCheck = $false
            }
            if ('Credential' -in $json.Hosts.$_.PSObject.Properties.Name) {
                $profiles.$_.Credential = (Import-IBCred $json.Hosts.$_.Credential $_)
            }
            if ($json.Hosts.$_.IgnoreCertificateValidation) {
                $profiles.$_.SkipCertificateCheck = $true
            }
        }
        $backup1x = $true
    }

    # backup the old 1.x config file and save the new version
    if ($backup1x) {
        Write-Verbose "Backing up imported v1 config file"
        Copy-Item $configFile "$configFile.v1" -Force
        Export-IBConfig
    }

}
