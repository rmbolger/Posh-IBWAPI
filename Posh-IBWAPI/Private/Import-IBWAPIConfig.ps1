function Import-IBWAPIConfig
{
    [CmdletBinding()]
    param()

    $config = @{
        CurrentHost = [string]::Empty;
        Hosts = @{};
    }

    if (Test-Path $script:ConfigFile) {

        # load the json content on disk to a pscustomobject
        $json = Get-Content $script:ConfigFile -Encoding UTF8 -Raw | ConvertFrom-Json

        # add the current host to the model
        $config.CurrentHost = $json.CurrentHost

        # add the rest of the host configs
        ($json.Hosts | Get-Member -MemberType NoteProperty).Name | ForEach-Object {
            $config.Hosts.$_ = @{}
            if (![string]::IsNullOrWhiteSpace($json.Hosts.$_.WAPIHost)) {
                $config.Hosts.$_.WAPIHost = $json.Hosts.$_.WAPIHost;
            }
            if (![string]::IsNullOrWhiteSpace($json.Hosts.$_.WAPIVersion)) {
                $config.Hosts.$_.WAPIVersion = $json.Hosts.$_.WAPIVersion;
            }
            if ($json.Hosts.$_.Credential) {
                $cred = $json.Hosts.$_.Credential
                $WAPIHost = $_

                # On Linux and MacOS, we are converting from a base64 string for the password rather
                # than a DPAPI encrypted SecureString. But it may not always be this way. So check for
                # the explicit boolean just to make sure.
                if ($cred.IsBase64) {
                    try {
                        $passPlain = [Text.Encoding]::Unicode.GetString([Convert]::FromBase64String($cred.Password))
                        $config.Hosts.$_.Credential = New-Object PSCredential($cred.Username,($passPlain | ConvertTo-SecureString -AsPlainText -Force))
                    } catch {
                        Write-Warning "Unable to convert Base64 Credential for $($WAPIHost): $($_.Exception.Message)"
                    }
                } else {
                    # Try to convert the password back into a SecureString and into a PSCredential
                    try {
                        $secPass = $cred.Password | ConvertTo-SecureString -ErrorAction Stop
                        $config.Hosts.$_.Credential = New-Object PSCredential($cred.Username,$secPass)
                    } catch {
                        Write-Warning "Unable to convert Credential for $($WAPIHost): $($_.Exception.Message)"
                    }
                }

            }
            if ($json.Hosts.$_.IgnoreCertificateValidation) {
                $config.Hosts.$_.IgnoreCertificateValidation = New-Object Management.Automation.SwitchParameter -ArgumentList $json.Hosts.$_.IgnoreCertificateValidation.IsPresent
            }
        }

    } else {
        Write-Verbose "No existing config file found"
    }

    return $config
}
