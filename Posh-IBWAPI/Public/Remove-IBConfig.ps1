function Remove-IBConfig
{
    [CmdletBinding()]
    param(
        [Parameter(ParameterSetName='Specific',Position=0,ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true)]
        [ValidateScript({Test-NonEmptyString $_ -ThrowOnFail})]
        [Alias('name')]
        [string]$ProfileName,
        [Parameter(ParameterSetName='All',Mandatory=$true)]
        [switch]$AllProfiles
    )

    Begin {
        # Ignore these calls when running stateless with an environment variable
        # based profile.
        if ('ENV' -eq (Get-CurrentProfile)) {
            Write-Warning "Remove-IBConfig is not available when using an environment variable based profile."
        }
    }

    Process {

        # Ignore these calls when running stateless with an environment variable
        # based profile.
        if ('ENV' -eq (Get-CurrentProfile)) {
            return
        }

        if ('All' -eq $PSCmdlet.ParameterSetName) {

            if ($AllProfiles) {
                Write-Verbose "Removing all connection profiles."

                # delete the config file if it exists
                $configFile = Get-ConfigFile
                if (Test-Path $configFile) {
                    Remove-Item $configFile -Force
                }

                Import-IBConfig
                return
            }

            # it's possible they called this with -AllProfiles:$false which is
            # weird but valid and we'll just not do anything

        }

        # decide which profile to remove
        $profToRemove = Get-CurrentProfile
        if ($ProfileName) {
            $profToRemove = $ProfileName
        }

        Write-Verbose "Removing $profToRemove profile"
        $profiles = Get-Profiles

        if ($profToRemove -in $profiles.Keys) {

            $profiles.Remove($profToRemove)

            # set a new CurrentProfile if necessary
            if ((Get-CurrentProfile) -eq $profToRemove) {
                Set-CurrentProfile ([string]::Empty)
                if ($profiles.Count -gt 0) {
                    Set-CurrentProfile @(($profiles.Keys | Sort-Object))[0]
                }
            }

        } else {
            Write-Warning "`"$profToRemove`" not found in the set of existing profiles."
            return
        }

        # save changes to disk

        # if this is the last entry, just delete the config file
        $configFile = Get-ConfigFile
        if ($profiles.Count -lt 1) {
            if (Test-Path $configFile -PathType Leaf) {
                Remove-Item $configFile -Force
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
