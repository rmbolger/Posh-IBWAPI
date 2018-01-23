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
        $json = Get-Content $script:ConfigFile -Encoding UTF8 | ConvertFrom-Json

        # add the current host to the model
        $config.CurrentHost = $json.CurrentHost

        # add the rest of the host configs
        ($json.Hosts | Get-Member -MemberType NoteProperty).Name | %{
            $config.Hosts.$_ = @{}
            if (![string]::IsNullOrWhiteSpace($json.Hosts.$_.WAPIHost)) {
                $config.Hosts.$_.WAPIHost = $json.Hosts.$_.WAPIHost;
            }
            if (![string]::IsNullOrWhiteSpace($json.Hosts.$_.WAPIVersion)) {
                $config.Hosts.$_.WAPIVersion = $json.Hosts.$_.WAPIVersion;
            }
            if ($json.Hosts.$_.Credential) {
                $cred = $json.Hosts.$_.Credential
                $config.Hosts.$_.Credential = New-Object PSCredential($cred.Username,($cred.Password | ConvertTo-SecureString));
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