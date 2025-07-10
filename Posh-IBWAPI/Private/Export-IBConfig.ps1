function Export-IBConfig
{
    [CmdletBinding()]
    param()

    $curProfile = Get-CurrentProfile
    $profiles = Get-Profiles

    # For vault-based config storage, each profile will exist as a unique secret
    # in the vault. For local config storage, we'll continue using a single JSON
    # file as in 3.x.

    if ($vaultCfg = Get-VaultConfig) {
        if ($vaultProfiles = Get-VaultProfiles -VaultConfig $vaultCfg) {

            # delete any vault profiles that no longer exist in memory
            foreach ($profName in @($vaultProfiles.Keys)) {
                if ($profName -notin $profiles.Keys) {
                    $secretName = $vaultCfg.Template -f $profName
                    Write-Debug "Removing vault profile '$secretName'."
                    $vaultProfiles.Remove($profName)
                    Remove-Secret -Vault $vaultCfg.Name -Name $secretName
                }
            }
        }
    }
    else {
        # prep the local config object we'll be converting to JSON later
        $cfgToExport = @{
            CurrentProfile = $curProfile
            Profiles = @{}
        }
    }

    foreach ($profName in $profiles.Keys) {

        $profRaw = @{
            WAPIHost             = $profiles.$profName.WAPIHost
            WAPIVersion          = $profiles.$profName.WAPIVersion
            Credential           = $null
            SkipCertificateCheck = $profiles.$profName.SkipCertificateCheck
            NoSession            = $profiles.$profName.NoSession
        }

        if ($vaultCfg) {
            # Since we can't rely on secret metadata to store whether this profile
            # is the current profile, we'll just add it to the JSON blob instead.
            $profRaw.Current = if ($curProfile -eq $profName) { $true } else { $false }
        }
        else {
            # add the raw profile to the export object
            $cfgToExport.Profiles.$profName = $profRaw
        }

        # deal with the credential
        $credSerialized = @{
            Username = $profiles.$profName.Credential.Username
        }

        # For vault storage, we're going to leave the serialized password
        # as plain text and rely on the vault's native encryption to protect it.
        # For local storage, we'll continue to use the DPAPI/Base64 method
        # depending on the platform since there's still no good way to encrypt
        # serialized SecureString values cross-platform in PowerShell 7+ unless
        # you provide your own key.

        if ($vaultCfg) {
            # store the plaintext password
            $credSerialized.Password = $profiles.$profName.Credential.GetNetworkCredential().Password
        }
        elseif ($IsWindows -or $PSEdition -eq 'Desktop') {
            # store the DPAPI encrypted password
            $credSerialized.Password = ConvertFrom-SecureString $profiles.$profName.Credential.Password
        }
        else {
            # store the Base64 encoded password
            $passPlain = $profiles.$profName.Credential.GetNetworkCredential().Password
            $credSerialized.Password = [Convert]::ToBase64String(
                [Text.Encoding]::Unicode.GetBytes($passPlain)
            )
            $credSerialized.IsBase64 = $true
        }

        $profRaw.Credential = $credSerialized

        # For vault profiles, we only want to store if it changed or doesn't already exist
        if ($vaultCfg) {

            $vaultProf = $vaultProfiles.$profName

            if ($profName -notin $vaultProfiles.Keys -or
                $profRaw.WAPIHost             -ne $vaultProf.WAPIHost -or
                $profRaw.WAPIVersion          -ne $vaultProf.WAPIVersion -or
                $profRaw.Credential.Username  -ne $vaultProf.Credential.Username -or
                $profRaw.Credential.Password  -ne $vaultProf.Credential.Password -or
                $profRaw.SkipCertificateCheck -ne $vaultProf.SkipCertificateCheck -or
                $profRaw.NoSession            -ne $vaultProf.NoSession -or
                $profRaw.Current              -ne $vaultProf.Current
            ) {

                $secretName = $vaultCfg.Template -f $profName
                Write-Debug "Storing vault profile '$secretName'."
                $secretJson = $profRaw | ConvertTo-Json -Compress

                Set-Secret -Vault $vaultCfg.Name -Name $secretName -Secret $secretJson
            }


        }

    }

    # we're done if we used the vault
    if ($vaultCfg) { return }

    # otherwise, save to disk if we have anything to save
    if ($profiles.Count -gt 0) {
        # Make sure the config folder exists
        $configFolder = Get-ConfigFolder

        New-Item $configFolder -Type Directory -ErrorAction Ignore

        # Save it to disk
        $configFile = Get-ConfigFile
        $cfgToExport | ConvertTo-Json -Depth 5 | Out-File $configFile -Encoding utf8
    }

}
