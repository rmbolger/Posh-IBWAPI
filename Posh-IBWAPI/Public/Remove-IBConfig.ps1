function Remove-IBConfig
{
    [CmdletBinding()]
    param(
        [ValidateScript({Test-NonEmptyString $_ -ThrowOnFail})]
        [Alias('name')]
        [string]$ProfileName,
        [switch]$AllProfiles
    )

    if ($AllProfiles) {

        Write-Verbose "Removing all connection profiles."

        # delete the config file if it exists
        if (Test-Path $script:ProfilesFile) {
            Remove-Item $script:ProfilesFile -Force
        }

        Import-IBConfig

    } else {

        # decide which profile to remove
        $profToRemove = $script:CurrentProfile
        if ($ProfileName) {
            $profToRemove = $ProfileName
        }

        Write-Verbose "Removing $profToRemove"

        if ($profToRemove -in $script:Profiles.Keys) {

            $script:Profiles.Remove($profToRemove)

            # set a new CurrentProfile if necessary
            if ($script:CurrentProfile -eq $profToRemove) {
                $script:CurrentProfile = [string]::Empty
                if ($script:Profiles.Count -gt 0) {
                    $script:CurrentProfile = @(($script:Profiles.Keys | Sort-Object))[0]
                }
            }

        } else {
            Write-Warning "`"$profToRemove`" not found in the set of existing profiles."
            return
        }

        # save changes to disk

        # if this is the last entry, just delete the config file
        if ($script:Profiles.Count -lt 1) {
            if (Test-Path $script:ConfigFile) {
                Remove-Item $script:ConfigFile -Force
                Import-IBConfig
            }
        } else {
            Export-IBConfig
        }

    }




    <#
    .SYNOPSIS
        Remove a WAPI connection profile.

    .DESCRIPTION
        When called with no parameters, the currently active connection profile will be removed.

        When called with -ProfileName, the specified profile will be removed.

        When called with -AllProfiles, all profiles will be removed.

    .PARAMETER ProfileName
        The name of the profile to remove.

    .PARAMETER AllProfiles
        If set, all profiles will be removed.

    .EXAMPLE
        Remove-IBConfig

        Remove the currently active connection profile.

    .EXAMPLE
        Remove-IBConfig -AllHosts

        Remove all connection profiles.

    .LINK
        Project: https://github.com/rmbolger/Posh-IBWAPI

    .LINK
        Set-IBConfig

    #>
}
