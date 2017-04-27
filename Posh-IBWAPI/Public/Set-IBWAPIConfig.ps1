function Set-IBWAPIConfig
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
        [switch]$IgnoreCertificateValidation
    )

    # We want to allow callers to save some of the normally tedious parameters
    # to this instance of the module so they don't need to supply them on
    # every subsequent function call.

    # NOTE: Script scoped variables in a module are effectively module scoped.
    # So $script:blah should be accessible within any module function but not directly
    # to the callers of module functions.

    if (![String]::IsNullOrWhiteSpace($WAPIHost)) {
        Write-Verbose "Saving WAPIHost as $WAPIHost"
        $script:WAPIHost = $WAPIHost
    }

    if ($WebSession) {
        Write-Verbose "Saving new WebSession with Credential for $($WebSession.Credentials.UserName)"
        $script:WebSession = $WebSession
    }

    if ($Credential) {
        Write-Verbose "Saving Credential for $($Credential.UserName)"
        $script:Credential = $Credential

        if (!$script:WebSession) {
            # Configure an empty WebSession if we don't have one already
            Write-Verbose "Creating empty WebSession with Credential for $($Credential.UserName)"
            $session = New-Object Microsoft.PowerShell.Commands.WebRequestSession
            $session.Credentials = $Credential.GetNetworkCredential()
            $script:WebSession = $session
        }
        else {
            # Update the credential in our existing WebSession
            Write-Verbose "Updating existing WebSession with Credential for $($Credential.UserName)"
            ($script:WebSession).Credentials = $Credential.GetNetworkCredential()
        }
    }

    # deal with setting IgnoreCertificateValidation
    if ($PSBoundParameters.ContainsKey('IgnoreCertificateValidation')) {
        Write-Verbose "Saving IgnoreCertificateValidation $IgnoreCertificateValidation"
        $script:IgnoreCertificateValidation = $IgnoreCertificateValidation
    }

    if (![String]::IsNullOrWhiteSpace($WAPIVersion)) {
        # While it may be considered bad practice when dealing with a well-versioned
        # REST API, we want to allow callers to automatically use the latest API
        # version without explicitly knowing what it is. So if they specify 'latest',
        # we'll query the latest version from Infoblox and set that.
        if ($WAPIVersion -eq 'latest') {
            # Query the grid master schema for the list of supported versions
            Write-Verbose "Querying schema for supported versions"
            $versions = (Invoke-IBWAPI -Uri "https://$($script:WAPIHost)/wapi/v1.0/?_schema" -WebSession $script:WebSession -IgnoreCertificateValidation:($script:IgnoreCertificateValidation)).supported_versions

            # Historically, these are returned in order. But just in case they aren't, we'll
            # explicitly sort them via the [Version] cast which is an easy way to make sure you
            # end up with 1,2,11,22 instead of 1,11,2,22.
            $versions = $versions | Sort-Object @{E={[Version]$_}}

            # set the most recent (last) one in the sorted list
            $script:WAPIVersion = $versions | Select-Object -Last 1
            Write-Verbose "Saved WAPIVersion as $($script:WAPIVersion)"
        }
        else {
            # Users familiar with the Infoblox WAPI might include a 'v' in their version
            # string because that's how you specify it in the URL, but we're going to do
            # that for them. So just strip it out if it's there.
            if ($WAPIVersion[0] -eq 'v') {
                $WAPIVersion = $WAPIVersion.Substring(1)
            }

            # validate it can actually be parsed by the Version object
            if ([Version]$WAPIVersion) {
                $script:WAPIVersion = $WAPIVersion
            }

            # WARNING: Both the sorting and the [Version] validation may break
            # in the future if Infoblox ever changes the way they name versions.
        }
    }




    <#
    .SYNOPSIS
        Set configuration values for this module.

    .DESCRIPTION
        Rather than specifying the same common parameter values to most of the function calls in this module, you can pre-set them with this function instead. They will be used automatically by other functions that support them unless overridden by the function's own parameters.

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

    .EXAMPLE
        Set-IBWAPIConfig -WAPIHost 'gridmaster.example.com'

        Set the hostname of the Infoblox API endpoint.

    .EXAMPLE
        Set-IBWAPIConfig -WAPIHost $gridmaster -WAPIVersion 2.2 -Credential (Get-Credential) -IgnoreCertificateValidation

        Set all of the basic parameters for an Infoblox WAPI connection, prompt for the credentials, and ignore certificate validation.

    .LINK
        Project: https://github.com/rmbolger/Posh-IBWAPI

    .LINK
        Get-IBWAPIConfig

    .LINK
        Get-IBSession

    .LINK
        Invoke-IBWAPI

    #>
}
