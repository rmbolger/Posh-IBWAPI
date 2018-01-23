function Save-IBWAPIConfig
{
    [CmdletBinding()]
    param(
        [Alias('host')]
        [string]$WAPIHost,
        [switch]$AllHosts
    )

    function CopyConfig($src,$target) {
        if ($src.WAPIHost) { $target.WAPIHost = $src.WAPIHost }
        if ($src.WAPIVersion) { $target.WAPIVersion = $src.WAPIVersion }
        if ($src.Credential) { $target.Credential = $src.Credential }
        if ($src.IgnoreCertificateValidation) { $target.IgnoreCertificateValidation = $src.IgnoreCertificateValidation }

        # We don't want to save WebSession because it doesn't serialize well and is
        # likely to be expired in the future anyway. BUT, we don't want to lose the
        # embedded Credential if an explicit one isn't already set. So pull it out and
        # save it.
        if ($src.WebSession -and !$src.Credential) {
            $netCred = $src.WebSession.Credentials
            $target.Credential = New-Object PSCredential($netCred.Username,($netCred.Password | ConvertTo-SecureString -AsPlainText -Force))
        }
    }

    # create an in-memory copy of the currently cold config data
    $coldConfig = Import-IBWAPIConfig

    if ($AllHosts) {

        # Loop through all of the existing hosts and overwrite any existing entries
        # in the cold config with a copy of the live config
        @($script:Config.Keys) | %{
            Write-Verbose "Saving $_"
            $coldConfig.Hosts.$_ = @{}
            CopyConfig $script:Config.$_ $coldConfig.Hosts.$_
        }

    } else {

        # decide which host to save
        $hostToSave = $script:CurrentHost
        if (![string]::IsNullOrWhiteSpace($WAPIHost)) {
            $hostToSave = $WAPIHost
        }

        # Overwrite the existing entry for the host if it exists
        if ($hostToSave -in $script:Config.Keys) {
            Write-Verbose "Saving $hostToSave"
            $coldConfig.Hosts.$hostToSave = @{}
            CopyConfig $script:Config.$hostToSave $coldConfig.Hosts.$hostToSave
        } else {
            Write-Warning "$hostToSave not found in the set of existing configs."
        }
    
    }

    # add the current host if it's set
    if (![string]::IsNullOrWhiteSpace($script:CurrentHost)) {
        $coldConfig.CurrentHost = $script:CurrentHost
    }

    Export-IBWAPIConfig $coldConfig




    <#
    .SYNOPSIS
        Persist WAPI configuration data to disk.

    .DESCRIPTION
        When calling this function with no parameters, the currently active set of config values will be persisted to the user's local profile.

        When called with -WAPIHost, the set of config values for that host will be persisted.

        When called with -AllHosts, all sets of config values will be persisted.

    .PARAMETER WAPIHost
        The fully qualified DNS name or IP address of the Infoblox WAPI endpoint (usually the grid master).

    .PARAMETER AllHosts
        If set, all sets of config values will be persisted to disk.

    .EXAMPLE
        Save-IBWAPIConfig

        Saves the currently active WAPI config set to disk.

    .EXAMPLE
        Save-IBWAPIConfig -AllHosts

        Saves all config sets to disk.

    .LINK
        Project: https://github.com/rmbolger/Posh-IBWAPI

    .LINK
        Set-IBWAPIConfig

    .LINK
        Remove-IBWAPIConfig

    #>
}