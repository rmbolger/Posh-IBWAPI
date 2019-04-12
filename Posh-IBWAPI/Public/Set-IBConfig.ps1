function Set-IBConfig
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
        [switch]$IgnoreCertificateValidation,
        [switch]$NoSwitchProfile
    )

    # We want to allow callers to save some of the normally tedious parameters
    # to this instance of the module so they don't need to supply them on
    # every subsequent function call.

    # NOTE: Script scoped variables in a module are effectively module scoped.
    # So $script:blah should be accessible within any module function but not directly
    # to the callers of module functions.

    # deal with hostname
    if (![String]::IsNullOrWhiteSpace($WAPIHost)) {

        # initialize a hashtable for this host if it doesn't exist
        if (!$script:Config.$WAPIHost) {
            $script:Config.$WAPIHost = @{WAPIHost=$WAPIHost}
        }

        # remove the old empty string config if it exists
        $script:Config.Remove('') | Out-Null

        # switch the current host if necessary
        if (!$NoSwitchProfile -and $WAPIHost -ne $script:CurrentHost) {
            $script:CurrentHost = $WAPIHost
            Write-Verbose "Switched config to $WAPIHost"
        }

        # make a shorthand reference to the host config to be modified
        $cfg = $script:Config.$WAPIHost
    }
    else {
        # make a shorthand reference to the host config to be modified
        $cfg = $script:Config.$script:CurrentHost
    }

    if ($WebSession) {
        Write-Verbose "Saving new WebSession with Credential for $($WebSession.Credentials.UserName)"
        $cfg.WebSession = $WebSession
    }

    if ($Credential) {
        Write-Verbose "Saving Credential for $($Credential.UserName)"
        $cfg.Credential = $Credential

        if (!$cfg.WebSession) {
            # Configure an empty WebSession if we don't have one already
            Write-Verbose "Creating empty WebSession with Credential for $($Credential.UserName)"
            $session = New-Object Microsoft.PowerShell.Commands.WebRequestSession
            $session.Credentials = $Credential.GetNetworkCredential()
            $cfg.WebSession = $session
        }
        else {
            # Update the credential in our existing WebSession
            Write-Verbose "Updating existing WebSession with Credential for $($Credential.UserName)"
            $cfg.WebSession.Credentials = $Credential.GetNetworkCredential()
        }
    }

    # deal with setting IgnoreCertificateValidation
    if ($PSBoundParameters.ContainsKey('IgnoreCertificateValidation')) {
        Write-Verbose "Saving IgnoreCertificateValidation $IgnoreCertificateValidation"
        $cfg.IgnoreCertificateValidation = $IgnoreCertificateValidation
    }

    if (![String]::IsNullOrWhiteSpace($WAPIVersion)) {
        # While it may be considered bad practice when dealing with a well-versioned
        # REST API, we want to allow callers to automatically use the latest API
        # version without explicitly knowing what it is. So if they specify 'latest',
        # we'll query the latest version from Infoblox and set that.
        if ($WAPIVersion -eq 'latest') {
            $cfg.WAPIVersion = (HighestVer $cfg.WAPIHost $cfg.WebSession -IgnoreCertificateValidation:$cfg.IgnoreCertificateValidation)
        }
        else {
            # Users familiar with the Infoblox WAPI might include a 'v' in their version
            # string because that's how you specify it in the URL, but we're going to do
            # that for them. So just strip it out if it's there.
            if ($WAPIVersion[0] -eq 'v') {
                $WAPIVersion = $WAPIVersion.Substring(1)
            }

            # validate it can actually be parsed by the Version object
            if (!($WAPIVersion -as [Version])) {
                throw "WAPIVersion is not a valid version string."
            }

            $cfg.WAPIVersion = $WAPIVersion
        }
        Write-Verbose "Saved WAPIVersion as $($cfg.WAPIVersion)"

        # WARNING: Both the sorting and the [Version] validation may break
        # in the future if Infoblox ever changes the way they name versions.
    }




    <#
    .SYNOPSIS
        Save configuration values for a WAPI host that will persist for the duration of this Powershell session.

    .DESCRIPTION
        Rather than specifying the same common parameter values to most of the function calls in this module, you can pre-set them with this function instead. They will be used automatically by other functions that support them unless overridden by the function's own parameters.

        Config values are saved per unique WAPIHost value. Calling this function with a new WAPIHost will switch the "current" config to the new host unless -NoSwitchProfile is used.

    .PARAMETER WAPIHost
        The fully qualified DNS name or IP address of the Infoblox WAPI endpoint (usually the grid master).

    .PARAMETER WAPIVersion
        The version of the Infoblox WAPI to make calls against (e.g. '2.2'). You may optionally specify 'latest' and the function will attempt to query the WAPI for the latest supported version. This will only work if WAPIHost and Credential or WebSession are included or already configured.

    .PARAMETER Credential
        Username and password for the Infoblox appliance. If -WebSession is not specified and not already configured, setting this will also set WebSession with these credentials.

    .PARAMETER WebSession
        A WebRequestSession object returned by Get-IBSession or set when using Invoke-IBWAPI with the -SessionVariable parameter.

    .PARAMETER IgnoreCertificateValidation
        If set, SSL/TLS certificate validation will be disabled.

    .PARAMETER NoSwitchProfile
        If set, the "current" WAPI host config will not switch to the specified -WAPIHost if different.

    .EXAMPLE
        Set-IBConfig -WAPIHost 'gridmaster.example.com'

        Set the hostname of the Infoblox API endpoint.

    .EXAMPLE
        Set-IBConfig -WAPIHost $gridmaster -WAPIVersion 2.2 -Credential (Get-Credential) -IgnoreCertificateValidation

        Set all of the basic parameters for an Infoblox WAPI connection, prompt for the credentials, and ignore certificate validation.

    .LINK
        Project: https://github.com/rmbolger/Posh-IBWAPI

    .LINK
        Get-IBConfig

    .LINK
        Get-IBSession

    .LINK
        Invoke-IBWAPI

    #>
}
