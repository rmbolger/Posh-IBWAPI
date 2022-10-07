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

    # Ignore these calls when running stateless with an environment variable
    # based profile.
    if ('ENV' -eq (Get-CurrentProfile)) {
        Write-Warning "Set-IBConfig is not available when using an environment variable based profile."
        return
    }

    $profiles = Get-Profiles

    if ($ProfileName) {
        if ($ProfileName -in $profiles.Keys) {
            # grab the referenced profile
            $cfg = $profiles.$ProfileName
            Write-Debug "Using profile $ProfileName"
        } else {
            # start a new profile
            $cfg = @{}
            Write-Debug "Starting new profile $ProfileName"
        }
    } else {
        if (Get-CurrentProfile) {
            # grab the current profile
            $ProfileName = Get-CurrentProfile
            $cfg = $profiles.$ProfileName
            Write-Debug "Using current profile $ProfileName"
        } else {
            # can't do anything with no current profile
            $PSCmdlet.ThrowTerminatingError([Management.Automation.ErrorRecord]::new(
                "ProfileName not specified and no active profile to modify.",
                $null, [Management.Automation.ErrorCategory]::InvalidArgument, $null
            ))
        }
    }

    if ($WAPIHost) {
        $cfg.WAPIHost = $WAPIHost
        Write-Debug "WAPIHost set to $($cfg.WAPIHost)"
    } elseif (-not $cfg.WAPIHost) {
        # we don't allow new profiles with no host
        $PSCmdlet.ThrowTerminatingError([Management.Automation.ErrorRecord]::new(
            "New profiles must contain a WAPIHost.",
            $null, [Management.Automation.ErrorCategory]::InvalidArgument, $null
        ))
    }

    if ($Credential) {
        $cfg.Credential = $Credential
        Write-Debug "Credential set to $($cfg.Credential.Username)"
    } elseif (-not $cfg.Credential) {
        # we don't allow new profiles with no credential
        $PSCmdlet.ThrowTerminatingError([Management.Automation.ErrorRecord]::new(
            "New profiles must contain a Credential.",
            $null, [Management.Automation.ErrorCategory]::InvalidArgument, $null
        ))
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
        $PSCmdlet.ThrowTerminatingError([Management.Automation.ErrorRecord]::new(
            "New profiles must contain a WAPIVersion.",
            $null, [Management.Automation.ErrorCategory]::InvalidArgument, $null
        ))
    }

    # deal with profile renames and add/overwrite the new/old profile
    if ($NewName -and $NewName -ne $ProfileName) {
        $profiles.Remove($ProfileName)
        $ProfileName = $NewName
        Write-Debug "Profile renamed to $ProfileName"
    }

    # add/overwrite the new/old profile
    $profiles.$ProfileName = $cfg

    # switch to the profile unless otherwise specified
    if (-not $NoSwitchProfile -and $ProfileName -ne (Get-CurrentProfile)) {
        Write-Verbose "Setting $ProfileName as the active profile"
        Set-CurrentProfile $ProfileName
    }

    # persist the changes
    Export-IBConfig
}
