function Remove-IBWAPIConfig
{
    [CmdletBinding()]
    param(
        [Alias('host')]
        [string]$WAPIHost,
        [switch]$AllHosts
    )

    if ($AllHosts) {

        Write-Verbose "Removing all config sets."

        # delete the config file if it exists
        if (Test-Path $script:ConfigFile) {
            Remove-Item $script:ConfigFile -Force
        }

        # load the now empty cold config
        $coldConfig = Import-IBWAPIConfig
        $script:CurrentHost = $coldConfig.CurrentHost
        $script:Config = $coldConfig.Hosts

    } else {

        # load the cold config
        $coldConfig = Import-IBWAPIConfig

        # decide which host to remove
        $hostToRemove = $script:CurrentHost
        if (![string]::IsNullOrWhiteSpace($WAPIHost)) {
            $hostToRemove = $WAPIHost
        }

        Write-Verbose "Removing $hostToRemove"

        # remove from memory first
        if ($hostToRemove -in $script:Config.Keys) {

            $script:Config.Remove($hostToRemove)

            # set a new CurrentHost if necessary
            if ($script:CurrentHost -eq $hostToRemove) {
                $script:CurrentHost = [string]::Empty
                if ($script:Config.Count -gt 0) {
                    $script:CurrentHost = @(($script:Config.Keys | Sort-Object))[0]
                }
            }

        } else {
            Write-Warning "$hostToRemove not found in the set of existing configs."
        }

        # if this is the last entry on disk, just remove the file
        if ($coldConfig.Hosts.Count -le 1 -and (Test-Path $script:ConfigFile)) {
            Remove-Item $script:ConfigFile -Force
        } else {
            # otherwise, remove just this entry
            if ($hostToRemove -in $coldConfig.Hosts.Keys) {
                $coldConfig.Hosts.Remove($hostToRemove)
            }

            # set the same CurrentHost as in memory
            $coldConfig.CurrentHost = $script:CurrentHost

            # do some additional processing before saving to disk
            @($coldConfig.Hosts.Keys) | %{
                # pre-serialize the PSCredential objects so that ConvertTo-Json doesn't strip the SecureString passwords
                if ('Credential' -in $coldConfig.Hosts.$_.Keys) {
                    $credSerialized = @{
                        Username = $coldConfig.Hosts.$_.Credential.Username;
                        Password = ConvertFrom-SecureString $coldConfig.Hosts.$_.Credential.Password;
                    }
                    $coldConfig.Hosts.$_.Credential = $credSerialized
                }
            }

            # Save the updated cold config to disk
            $coldConfig | ConvertTo-Json -Depth 5 | Out-File $script:ConfigFile -Encoding utf8
        }

    }




    <#
    .SYNOPSIS
        Remove WAPI configuration data from memory and disk.

    .DESCRIPTION
        When calling this function with no parameters, the currently active set of config values will be removed.

        When called with -WAPIHost, the set of config values for that host will be removed.

        When called with -AllHosts, all sets of config values will be removed.

    .PARAMETER WAPIHost
        The fully qualified DNS name or IP address of the Infoblox WAPI endpoint (usually the grid master).

    .PARAMETER AllHosts
        If set, all sets of config values will be removed.

    .EXAMPLE
        Remove-IBWAPIConfig

        Removes the currently active WAPI config set from memory and disk.

    .EXAMPLE
        Remove-IBWAPIConfig -AllHosts

        Removes all config sets from memory and disk.

    .LINK
        Project: https://github.com/rmbolger/Posh-IBWAPI

    .LINK
        Set-IBWAPIConfig

    .LINK
        Save-IBWAPIConfig

    #>
}
