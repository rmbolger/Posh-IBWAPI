function Export-IBConfig
{
    [CmdletBinding()]
    param()

    $cfgToExport = @{
        CurrentProfile = Get-CurrentProfile
        Profiles = @{}
    }

    # ConvertTo-Json won't serialize the SecureString passwords in the PSCredential objects,
    # so we have to do some manual conversion into Username/Password combos that Import-IBConfig
    # will then re-hydrate later.

    $profiles = Get-Profiles

    foreach ($profName in $profiles.Keys) {

        $cfgToExport.Profiles.$profName = @{
            WAPIHost             = $profiles.$profName.WAPIHost
            WAPIVersion          = $profiles.$profName.WAPIVersion
            Credential           = $null
            SkipCertificateCheck = $profiles.$profName.SkipCertificateCheck
        }

        if ($null -ne $profiles.$profName.Credential) {

            $credSerialized = @{
                Username = $profiles.$profName.Credential.Username
            }

            # ConvertFrom-SecureString is only really supported on Windows because
            # it relies on DPAPI to do encryption which doesn't exist on other platforms.
            # From PowerShell 6.0-6.1, using on non-Windows would throw an error.
            # In PowerShell 6.2+, it works again but only obfuscates the text instead
            # of encrypting it.
            # We're going to Base64 encode the password on all non-Windows systems
            # until there's a better cross-platform solution for encrypting it.

            if ($IsWindows -or
                'PSEdition' -notin $PSVersionTable.Keys -or
                'Desktop' -eq $PSVersionTable.PSEdition)
            {
                $credSerialized.Password = ConvertFrom-SecureString $profiles.$profName.Credential.Password
            }
            else
            {
                $passPlain = $profiles.$profName.Credential.GetNetworkCredential().Password
                $credSerialized.Password = [Convert]::ToBase64String(
                    [Text.Encoding]::Unicode.GetBytes($passPlain)
                )
                $credSerialized.IsBase64 = $true
            }
            $cfgToExport.Profiles.$profName.Credential = $credSerialized
        }
    }

    if ($profiles.Count -gt 0) {
        # Make sure the config folder exists
        $configFolder = Get-ConfigFolder
        New-Item $configFolder -Type Directory -ErrorAction Ignore

        # Save it to disk
        $configFile = Get-ConfigFile
        $cfgToExport | ConvertTo-Json -Depth 5 | Out-File $configFile -Encoding utf8
    }

}
