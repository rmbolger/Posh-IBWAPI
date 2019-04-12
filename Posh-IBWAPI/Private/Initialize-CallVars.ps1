function Initialize-CallVars
{
    [CmdletBinding()]
    param(
        [Alias('host')]
        [string]$WAPIHost,
        [Alias('version')]
        [string]$WAPIVersion,
        [PSCredential]$Credential,
        [Alias('session')]
        [Microsoft.PowerShell.Commands.WebRequestSession]$WebSession,
        [switch]$SkipCertificateCheck,
        [Parameter(ValueFromRemainingArguments = $true)]
        $Splat
    )

    $psb = $PSBoundParameters

    # The purpose of this function is to provide an easy way to get the
    # merged set of common connection parameters to use against
    # Invoke-IBWAPI. Calling functions will pass their set of explicit
    # parameters and we will merge them with the saved set for the
    # currently active WAPIHost.  Explicit params always override saved
    # set params.

    # Remove any non-connection related parameters we were passed
    $connParams = 'WAPIHost','WAPIVersion','Credential','WebSession','SkipCertificateCheck'
    foreach ($key in @($psb.Keys)) {
        if ($key -notin $connParams) {
            $psb.Remove($key) | Out-Null
        }
    }

    # make sure we have a non-empty WAPIHost
    if ([String]::IsNullOrWhiteSpace($psb.WAPIHost)) {
        if ([String]::IsNullOrWhiteSpace($script:CurrentHost)) {
            throw "WAPIHost missing or empty."
        }
        else {
            # use the saved value
            $psb.WAPIHost = $script:CurrentHost
            Write-Verbose "using saved WAPIHost $($psb.WAPIHost)"

            # remove the empty string config if it exists
            $script:Config.Remove('') | Out-Null
        }
    }

    # make sure a config exists for this host
    if ($script:Config[$psb.WAPIHost]) { $cfg = $script:Config[$psb.WAPIHost] }
    else { $cfg = $script:Config[''] }

    # check the version
    if ([String]::IsNullOrWhiteSpace($psb.WAPIVersion)) {
        if ([String]::IsNullOrWhiteSpace($cfg.WAPIVersion)) {
            throw "WAPIVersion missing or empty."
        }
        else {
            # use the saved value
            $psb.WAPIVersion = $cfg.WAPIVersion
            Write-Verbose "using saved WAPIVersion $($psb.WAPIVersion)"
        }
    }
    else {
        # sanity check the explicit version string

        # strip the 'v' prefix if they used it on accident
        if ($psb.WAPIVersion[0] -eq 'v') {
            $psb.WAPIVersion = $psb.WAPIVersion.Substring(1)
        }

        # check format using a [Version] cast
        if (!($psb.WAPIVersion -as [Version])) {
            throw "WAPIVersion is not a valid version string."
        }
    }

    # check Credential and WebSession
    if (!$psb.Credential -and $cfg.Credential) {
        $psb.Credential = $cfg.Credential
        Write-Verbose "using saved Credential for $($psb.Credential.UserName)"
    }
    if (!$psb.WebSession -and $cfg.WebSession) {
        $psb.WebSession = $cfg.WebSession
        Write-Verbose "using saved WebSession for $($psb.WebSession.Credentials.UserName)"
    }
    if (!$psb.Credential -and !$psb.WebSession) {
        throw "No credentials supplied via Credential or WebSession"
    }

    if (!$psb.ContainsKey('SkipCertificateCheck') -and
        $cfg -and $cfg.ContainsKey('SkipCertificateCheck')) {
        $psb.SkipCertificateCheck = $cfg.SkipCertificateCheck
        Write-Verbose "using saved Ignore value $($psb.SkipCertificateCheck)"
    }

    # return our modified PSBoundParameters
    $psb
}
