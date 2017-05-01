function Get-IBWAPIConfig
{
    [CmdletBinding()]
    param(
        [string]$WAPIHost,
        [switch]$List
    )

    if ($List -and $script:Config) {
        # list all configs
        foreach ($hostConfig in $script:Config.Values) {
            [PSCustomObject]$hostConfig | Select-Object WAPIHost,WAPIVersion,Credential,WebSession,IgnoreCertificateValidation
        }
    }
    elseif ($script:Config -and $WAPIHost) {
        if ($script:Config.$WAPIHost) {
            # show the specified config
            [PSCustomObject]$script:Config.$WAPIHost | Select-Object WAPIHost,WAPIVersion,Credential,WebSession,IgnoreCertificateValidation
        } else {
            # show empty config
            [PSCustomObject]@{
                WAPIHost=$null;
                WAPIVersion=$null;
                Credential=$null;
                WebSession=$null;
                IgnoreCertificateValidation=$null;
            }
        }
    }
    elseif ($script:Config -and $script:CurrentHost) {
        # show the current config
        [PSCustomObject]$script:Config.$script:CurrentHost | Select-Object WAPIHost,WAPIVersion,Credential,WebSession,IgnoreCertificateValidation
    }
    else {
        # show empty config
        [PSCustomObject]@{
            WAPIHost=$null;
            WAPIVersion=$null;
            Credential=$null;
            WebSession=$null;
            IgnoreCertificateValidation=$null;
        }
    }





    <#
    .SYNOPSIS
        Get the current set of configuration values for this module.

    .DESCRIPTION
        When calling this function with no parameters, the currently active set of config values will be returned. These values will be used by related function calls to the Infoblox API unless they are overridden by the function's own parameters.

        When called with -WAPIHost, the set of config values for that host will be returned. When called with -List, all sets of config values will be returned.

    .PARAMETER WAPIHost
        The fully qualified DNS name or IP address of the Infoblox WAPI endpoint (usually the grid master).

    .PARAMETER List
        If set, list all config sets currently stored. Otherwise, just list the currently active set.

    .OUTPUTS
        [PSCustomObject]
        One or more config sets for this module.

    .EXAMPLE
        Get-IBWAPIConfig

        Get the current configuration values.

    .EXAMPLE
        Get-IBWAPIConfig -List

        Get all sets of configuration values.

    .LINK
        Project: https://github.com/rmbolger/Posh-IBWAPI

    .LINK
        Set-IBWAPIConfig

    .LINK
        Get-IBObject

    #>
}