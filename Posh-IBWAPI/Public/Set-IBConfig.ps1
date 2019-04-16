function Set-IBConfig
{
    [CmdletBinding()]
    param(
        [ValidateScript({Test-NonEmptyString $_ -ThrowOnFail})]
        [Alias('name')]
        [string]$ProfileName,
        [Alias('host')]
        [ValidateScript({Test-NonEmptyString $_ -ThrowOnFail})]
        [string]$WAPIHost,
        [Alias('version')]
        [ValidateScript({Test-VersionString $_ -AllowLatest -ThrowOnFail})]
        [string]$WAPIVersion,
        [PSCredential]$Credential,
        [switch]$SkipCertificateCheck,
        [ValidateScript({Test-NonEmptyString $_ -ThrowOnFail})]
        [string]$NewName,
        [switch]$NoSwitchProfile
    )

    # This function allows callers to save connection parameters so they don't
    # need to supply them on every subsequent function call.

    if ($ProfileName) {
        if ($ProfileName -in $script:Profiles.Keys) {
            # grab the referenced profile
            $cfg = $script:Profiles.$ProfileName
            Write-Debug "Using profile $ProfileName"
        } else {
            # start a new profile
            $cfg = @{}
            Write-Debug "Starting new profile $ProfileName"
        }
    } else {
        if ($ProfileName = (Get-CurrentProfile)) {
            # grab the current profile
            $cfg = $script:Profiles.$ProfileName
            Write-Debug "Using current profile $ProfileName"
        } else {
            # can't do anything with no current profile
            throw "ProfileName not specified and no active profile to modify."
        }
    }

    if ($WAPIHost) {
        $cfg.WAPIHost = $WAPIHost
        Write-Debug "WAPIHost set to $($cfg.WAPIHost)"
    } elseif (-not $cfg.WAPIHost) {
        # we don't allow new profiles with no host
        throw "New profiles must contain a WAPIHost."
    }

    if ($Credential) {
        $cfg.Credential = $Credential
        Write-Debug "Credential set to $($cfg.Credential.Username)"
    } elseif (-not $cfg.Credential) {
        # we don't allow new profiles with no credential
        throw "New profiles must contain a Credential."
    }

    # SkipCertificateCheck defaults to false, but can also be explicitly set to false
    # so don't just assume it's true if the flag was specified.
    if ('SkipCertificateCheck' -in $PSBoundParameters.Keys) {
        $cfg.SkipCertificateCheck = $SkipCertificateCheck.IsPresent
        Write-Debug "SkipCertificateCheck set to $($cfg.SkipCertificateCheck)"
    } elseif (-not ('SkipCertificateCheck' -in $cfg.Keys)) {
        $cfg.SkipCertificateCheck = $false
    }

    if ($WAPIVersion) {
        if ('latest' -eq $WAPIVersion) {
            # query the latest version using the connection parameters we've
            # already established
            $version = HighestVer @cfg
            $cfg.WAPIVersion = $version
        } else {
            $cfg.WAPIVersion = $WAPIVersion
        }
        Write-Debug "WAPIVersion set to $($cfg.WAPIVersion)"
    } elseif (-not $cfg.WAPIVersion) {
        # we don't allow new profiles with no WAPIVersion
        throw "New profiles must contain a WAPIVersion."
    }

    # deal with profile renames and add/overwrite the new/old profile
    if ($NewName -and $NewName -ne $ProfileName) {
        $script:Profiles.Remove($ProfileName)
        $ProfileName = $NewName
        Write-Debug "Profile renamed to $ProfileName"
    }

    # add/overwrite the new/old profile
    $script:Profiles.$ProfileName = $cfg

    # switch to the profile unless otherwise specified
    if (-not $NoSwitchProfile) {
        $script:CurrentProfile = $ProfileName
    }

    # save the changes to disk
    Export-IBConfig


    <#
    .SYNOPSIS
        Save connection parameters to a profile to avoid needing to supply them to future functions.

    .DESCRIPTION
        Rather than specifying the same common parameter values to most of the function calls in this module, you can pre-set them with this function instead. They will be used automatically by other functions that support them unless overridden by the function's own parameters.

        Calling this function with a profile name will update that profile's values and switch the current profile to the specified one unless -NoSwitchProfile is used. When a profile name is not specified, the current profile's values will be updated with any specified changes.

    .PARAMETER ProfileName
        The name of the profile to create or modify.

    .PARAMETER WAPIHost
        The fully qualified DNS name or IP address of the Infoblox WAPI endpoint (usually the grid master).

    .PARAMETER WAPIVersion
        The version of the Infoblox WAPI to make calls against (e.g. '2.2'). You may optionally specify 'latest' and the function will attempt to query the WAPI for the latest supported version.

    .PARAMETER Credential
        Username and password for the Infoblox appliance.

    .PARAMETER SkipCertificateCheck
        If set, SSL/TLS certificate validation will be disabled for this profile.

    .PARAMETER NoSwitchProfile
        If set, the current profile will not switch to the specified -ProfileName if different.

    .EXAMPLE
        Set-IBConfig -ProfileName 'gm-admin'

        Switch to the 'gm-admin' profile, but make no changes.

    .EXAMPLE
        Set-IBConfig -ProfileName 'gm-admin' -WAPIHost gm.example.com -WAPIVersion 2.2 -Credential (Get-Credential) -SkipCertificateCheck

        Create or update the 'gm-admin' profile with all basic connection parameters for an Infoblox WAPI connection. This will also prompt for the credentials and skip certificate validation.

    .EXAMPLE
        Set-IBConfig -WAPIVersion 2.5

        Update the current profile to WAPI version 2.5

    .LINK
        Project: https://github.com/rmbolger/Posh-IBWAPI

    .LINK
        Get-IBConfig

    .LINK
        Invoke-IBWAPI

    #>
}
