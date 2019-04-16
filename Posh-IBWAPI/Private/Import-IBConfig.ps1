function Import-IBConfig
{
    [CmdletBinding()]
    param()

    $script:CurrentProfile = [string]::Empty
    $script:Profiles = @{}
    $profiles = $script:Profiles

    if (-not $script:Sessions) {
        $script:Sessions = @{}
    }

    # return early if there's no file to load
    if (-not (Test-Path $script:ConfigFile)) { return }

    # declare an internal function for de-serializing credentials
    function ParseCred {
        [CmdletBinding()]
        param(
            [PSObject]$importedCred,
            [string]$profileName
        )

        # On Linux and MacOS, we are converting from a base64 string for the password rather
        # than a DPAPI encrypted SecureString. But it may not always be this way. So check for
        # the explicit boolean just to make sure.
        if ($importedCred.IsBase64) {
            try {
                $passPlain = [Text.Encoding]::Unicode.GetString([Convert]::FromBase64String($importedCred.Password))
            } catch {
                Write-Warning "Unable to convert Base64 Credential for $($profileName): $($_.Exception.Message)"
                return $null
            }
            return (New-Object PSCredential($importedCred.Username,($passPlain | ConvertTo-SecureString -AsPlainText -Force)))
        } else {
            # Try to convert the password back into a SecureString and into a PSCredential
            try {
                $secPass = $importedCred.Password | ConvertTo-SecureString -ErrorAction Stop
            } catch {
                Write-Warning "Unable to convert Credential for $($profileName): $($_.Exception.Message)"
                return $null
            }
            return (New-Object PSCredential($importedCred.Username,$secPass))
        }
    }

    # load the json content on disk to a pscustomobject
    $json = Get-Content $script:ConfigFile -Encoding UTF8 -Raw | ConvertFrom-Json
    $propNames = @($json.PSObject.Properties.Name)
    $backup1x = $false

    # grab the current profile
    if ('CurrentProfile' -in $propNames) {
        $script:CurrentProfile = $json.CurrentProfile
    } elseif ('CurrentHost' -in $propNames) {
        # allow for legacy 1.x config import
        $script:CurrentProfile = $json.CurrentHost
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
                $profiles.$_.Credential = (ParseCred $json.Profiles.$_.Credential $_)
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
                $profiles.$_.Credential = (ParseCred $json.Hosts.$_.Credential $_)
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
        Copy-Item $script:ConfigFile "$($script:ConfigFile).v1" -Force
        Export-IBConfig
    }

}
