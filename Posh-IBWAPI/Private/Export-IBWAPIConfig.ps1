function Export-IBWAPIConfig
{
    [CmdletBinding()]
    param([hashtable]$coldConfig)

    # pre-serialize the PSCredential objects so that ConvertTo-Json doesn't strip the SecureString passwords
    @($coldConfig.Hosts.Keys) | %{

        if ('Credential' -in $coldConfig.Hosts.$_.Keys) {

            # ConvertFrom-SecureString is currently only supported on Windows OSes because it
            # depends on DPAPI and throws an ugly error on Linux/MacOS. So for now, we're just
            # going to base64 encode the password on non-Windows and hope for better support
            # in future versions of PowerShell Core.
            $credSerialized = @{ Username = $coldConfig.Hosts.$_.Credential.Username }
            if ('PSEdition' -notin $PSVersionTable.Keys -or $PSVersionTable.PSEdition -eq 'Desktop' -or $IsWindows) {
                $credSerialized.Password = ConvertFrom-SecureString $coldConfig.Hosts.$_.Credential.Password
            } else {
                $passPlain = $coldConfig.Hosts.$_.Credential.GetNetworkCredential().Password
                $credSerialized.Password = [Convert]::ToBase64String([System.Text.Encoding]::Unicode.GetBytes($passPlain))
                $credSerialized.IsBase64 = $true
            }
            $coldConfig.Hosts.$_.Credential = $credSerialized

        }
    }

    # Make sure the config folder exists
    New-Item $script:ConfigFolder -Type Directory -ErrorAction SilentlyContinue

    # Save it to disk.
    $coldConfig | ConvertTo-Json -Depth 5 | Out-File $script:ConfigFile -Encoding utf8

}