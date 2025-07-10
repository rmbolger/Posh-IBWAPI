function Initialize-CallVars
{
    [CmdletBinding()]
    param(
        [Alias('host')]
        [string]$WAPIHost,
        [Alias('version')]
        [string]$WAPIVersion,
        [PSCredential]$Credential,
        [switch]$SkipCertificateCheck,
        [switch]$NoSession,
        [string]$ProfileName,
        [Parameter(ValueFromRemainingArguments=$true)]
        $ExtraParams
    )

    $psb = $PSBoundParameters

    # The purpose of this function is to provide an easy way to get the
    # merged set of common connection parameters to use against
    # Invoke-IBWAPI. Calling functions will pass their set of explicit
    # parameters and we will merge them with the saved set for the
    # currently active profile.
    # - Explicit profile overrides implicit profile.
    # - Explicit params override implicit and explicit profile params.

    # Remove any non-connection related parameters we were passed
    $connParams = 'WAPIHost','WAPIVersion','Credential','SkipCertificateCheck','NoSession'
    foreach ($key in @($psb.Keys)) {
        if ($key -notin $connParams) {
            $null = $psb.Remove($key)
        }
    }

    # determine which base profile to use
    if ($ProfileName) {
        Write-Debug "Explicit profile: $ProfileName"
        $profName = $ProfileName
    } else {
        $profName = Get-CurrentProfile
        Write-Debug "Implicit profile: $profName"
    }
    $prof = (Get-Profiles).$profName

    # make sure we have a WAPIHost
    if (-not $psb.WAPIHost) {
        if (-not $prof.WAPIHost) {
            throw "WAPIHost missing or empty."
        } else {
            # use the saved value
            $psb.WAPIHost = $prof.WAPIHost
        }
    } else {
        Write-Debug "Overriding saved WAPIHost with $($psb.WAPIHost)"
    }

    # make sure we have a WAPIVersion
    if (-not $psb.WAPIVersion) {
        if (-not $prof.WAPIVersion) {
            throw "WAPIVersion missing or empty."
        } else {
            # use the saved value
            $psb.WAPIVersion = $prof.WAPIVersion
        }
    } else {
        Write-Debug "Overriding saved WAPIVersion with $($psb.WAPIVersion)"
    }

    # make sure we have a Credential
    if (-not $psb.Credential) {
        if (-not $prof.Credential) {
            throw "Credential is missing or empty."
        } else {
            # use the saved value
            $psb.Credential = $prof.Credential
        }
    } else {
        Write-Debug "Overriding saved Credential with $($psb.Credential.Username)"
    }

    # deal with SKipCertificateCheck
    if ('SkipCertificateCheck' -in $psb.Keys) {
        Write-Debug "Overriding saved SkipCertificateCheck with $($psb.SkipCertificateCheck.IsPresent)"
    } else {
        # use the saved value
        $psb.SkipCertificateCheck = $prof.SkipCertificateCheck
    }

    # deal with NoSession
    if ('NoSession' -in $psb.Keys) {
        Write-Debug "Overriding saved NoSession with $($psb.NoSession.IsPresent)"
    } else {
        # use the saved value
        $psb.NoSession = $prof.NoSession
    }

    # return our modified PSBoundParameters
    $psb
}
