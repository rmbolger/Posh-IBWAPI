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

    # Check for an environment variable based profile overriding anything else
    if ($envProfile = Get-EnvProfile) {

        Set-CurrentProfile 'ENV'
        $profiles.ENV = $envProfile

        Write-Verbose "Using env variable profile $($envProfile.Credential.Username) @ $($envProfile.WAPIHost) $($envProfile.WAPIVersion)"

        # don't bother trying to load the local profiles
        return
    }

    # Check for Vault based profile config
    if ($vaultCfg = $script:VaultConfig = (Get-VaultConfig -Refresh)) {

        $vaultProfiles = Get-VaultProfiles -VaultConfig $vaultCfg

        foreach ($profName in $vaultProfiles.Keys) {

            $profRaw = $vaultProfiles.$profName

            # hydrate the PSCredential from the plaintext username/password
            $secPass = $profRaw.Credential.Password | ConvertTo-SecureString -AsPlainText -Force
            $profCred = [pscredential]::new($profRaw.Credential.Username, $secPass)

            # hydrate the raw profile
            $profiles.$profName = @{
                WAPIHost    = $profRaw.WAPIHost
                WAPIVersion = $profRaw.WAPIVersion
                Credential  = $profCred
                SkipCertificateCheck = $profRaw.SkipCertificateCheck
            }

            # set it as current if appropriate
            if ($profRaw.Current) {
                Set-CurrentProfile $profName
            }
        }

        # no need to continue processing a local config
        return
    }

    # If we've gotten this far, there's no ENV profile or working Vault config
    # So just try to load the local config

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

    # grab the current profile
    if ('CurrentProfile' -in $propNames) {
        Set-CurrentProfile $json.CurrentProfile
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
    }

}
