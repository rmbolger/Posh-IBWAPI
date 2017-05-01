function Get-IBWAPIConfig
{
    [CmdletBinding()]
    param(
        [switch]$List
    )

    if ($List -and $script:Config) {
        # list all configs
        foreach ($hostConfig in $script:Config.Values) {
            [PSCustomObject]$hostConfig
        }
    }
    elseif ($script:Config -and $script:CurrentHost) {
        # show the current config
        [PSCustomObject]$script:Config.$script:CurrentHost
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
        The configuration values returned by this function will automatically be used by related function calls to the Infoblox API unless they are overridden by the function's own parameters.

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