function Export-IBConfig
{
    [CmdletBinding()]
    param()

    $coldConfig = @{
        CurrentProfile = $script:CurrentProfile
        Profiles = @{}
    }
    $profiles = $coldConfig.Profiles

    # ConvertTo-Json won't serialize the SecureString passwords in the PSCredential objects,
    # so we have to do some manual conversion into Username/Password combos that Import-IBConfig
    # will then re-hydrate later.
    $script:Profiles.Keys | ForEach-Object {
        $profiles.$_ = @{
            WAPIHost = $script:Profiles.$_.WAPIHost
            WAPIVersion = $script:Profiles.$_.WAPIVersion
            Credential = $null
            SkipCertificateCheck = $script:Profiles.$_.SkipCertificateCheck
        }
        if ($null -ne $script:Profiles.$_.Credential) {

            $credSerialized = @{ Username = $script:Profiles.$_.Credential.Username }

            # ConvertFrom-SecureString is currently only supported on Windows OSes because it
            # depends on DPAPI and throws an ugly error on Linux/MacOS. So for now, we're just
            # going to base64 encode the password on non-Windows and hope for better support
            # in future versions of PowerShell Core.
            if ('PSEdition' -notin $PSVersionTable.Keys -or $PSVersionTable.PSEdition -eq 'Desktop' -or $IsWindows) {
                $credSerialized.Password = ConvertFrom-SecureString $script:Profiles.$_.Credential.Password
            } else {
                $passPlain = $script:Profiles.$_.Credential.GetNetworkCredential().Password
                $credSerialized.Password = [Convert]::ToBase64String([System.Text.Encoding]::Unicode.GetBytes($passPlain))
                $credSerialized.IsBase64 = $true
            }
            $profiles.$_.Credential = $credSerialized
        }
    }

    # Make sure the config folder exists
    New-Item $script:ConfigFolder -Type Directory -ErrorAction SilentlyContinue

    # Save it to disk.
    $coldConfig | ConvertTo-Json -Depth 5 | Out-File $script:ConfigFile -Encoding utf8

}
