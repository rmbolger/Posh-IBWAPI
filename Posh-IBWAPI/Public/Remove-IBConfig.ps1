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

        $profiles = Get-Profiles

        if ('All' -eq $PSCmdlet.ParameterSetName) {

            if (-not $AllProfiles) {
                # For some reason they used -AllProfiles:$false which is
                # weird but valid. So we'll just not do anything.
                return
            }

            Write-Verbose "Removing all connection profiles."

            # remove the profiles from memory
            foreach ($profName in @($profiles.Keys)) {
                $profiles.Remove($profName)
            }

            # erase the current profile name
            Set-CurrentProfile ([string]::Empty)

            # delete the config file if it exists
            $configFile = Get-ConfigFile
            if (Test-Path $configFile) {
                Remove-Item $configFile -Force
            }

            # persist the changes and return
            Export-IBConfig
            return
        }

        # decide which profile to remove
        $profToRemove = if ($ProfileName) { $ProfileName } else { Get-CurrentProfile }
        Write-Verbose "Removing $profToRemove profile"

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

        # if this is the last entry, just delete the config file
        $configFile = Get-ConfigFile
        if ($profiles.Count -eq 0 -and (Test-Path $configFile -PathType Leaf)) {
            Remove-Item $configFile -Force
        }

        # persist the changes
        Export-IBConfig
    }
}
