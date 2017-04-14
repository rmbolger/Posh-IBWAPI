function Set-IBWAPIConfig
{
    [CmdletBinding()]
    param(
        [string]$ComputerName,
        [string]$APIVersion,
        [PSCredential]$Credential,
        [Microsoft.PowerShell.Commands.WebRequestSession]$WebSession,
        [bool]$IgnoreCertificateValidation
    )

    # We want to allow callers to save some of the normally tedious parameters
    # to this instance of the module so they don't need to supply them on
    # every subsequent function call.

    # NOTE: Script scoped variables in a module are effectively module scoped.
    # So $script:blah should be accessible within any module function but not directly
    # to the callers of module functions.

    if (![String]::IsNullOrWhiteSpace($ComputerName)) {
        $script:ComputerName = $ComputerName
    }

    if ($Credential) {
        $script:Credential = $Credential

        # Configure an empty WebSession if we don't have one already and a separate
        # one wasn't passed in.
        if (!$WebSession -and !$script:WebSession) {
            $session = New-Object Microsoft.PowerShell.Commands.WebRequestSession
            $session.Credentials = $Credential.GetNetworkCredential()
            $script:WebSession = $session
        }
    }

    if ($WebSession) {
        $script.WebSession = $WebSession
    }

    if ($PSBoundParameters.ContainsKey('IgnoreCertificateValidation')) {
        $script:IgnoreCertificateValidation = $IgnoreCertificateValidation
    }

    if (![String]::IsNullOrWhiteSpace($APIVersion)) {
        # While it may be considered bad practice when dealing with a well-versioned
        # REST API, we want to allow callers to automatically use the latest API
        # version without explicitly knowing what it is. So if they specify 'latest',
        # we'll query the latest version from Infoblox and set that.
        if ($APIVersion -eq 'latest') {
            # Query the grid master schema for the list of supported versions
            $versions = (Invoke-IBWAPI -Uri "https://$($script:ComputerName)/wapi/v1.0/?_schema" -WebSession $script:WebSession -IgnoreCertificateValidation $script:IgnoreCertificateValidation).supported_versions

            # Historically, these are returned in order. But just in case they aren't, we'll
            # explicitly sort them via the [Version] cast which is an easy way to make sure you
            # end up with 1,2,11,22 instead of 1,11,2,22.
            $versions = $versions | Sort-Object @{E={[Version]$_}}

            # set the most recent (last) one in the sorted list
            $script:APIVersion = $versions | Select-Object -Last 1
        }
        else {
            # Users familiar with the Infoblox WAPI might include a 'v' in their version
            # string because that's how you specify it in the URL, but we're going to do
            # that for them. So just strip it out if it's there.
            if ($APIVersion[0] -eq 'v') {
                $APIVersion = $APIVersion.Substring(1)
            }

            # validate it can actually be parsed by the Version object
            if ([Version]$APIVersion) {
                $script:APIVersion = $APIVersion
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

    .PARAMETER ComputerName
        The fully qualified DNS name or IP address of the Infoblox WAPI endpoint (usually the grid master).

    .PARAMETER APIVersion
        The version of the Infoblox WAPI to make calls against (e.g. '2.2'). You may optionally specify 'latest' and the function will attempt to query the WAPI for the latest supported version. This will only work if ComputerName and Credential or WebSession are included or already configured.

    .PARAMETER Credential
        Username and password for the Infoblox appliance. If -WebSession is not specified and not already configured, setting this will also set WebSession with these credentials.

    .PARAMETER WebSession
        A WebRequestSession object returned by Get-IBSession or set when using Invoke-IBWAPI with the -SessionVariable parameter.

    .PARAMETER IgnoreCertificateValidation
        If $true, SSL/TLS certificate validation will be disabled.

    .EXAMPLE
        Set-IBWAPIConfig -ComputerName 'gridmaster.example.com'

        Set the hostname of the Infoblox API endpoint.

    .EXAMPLE
        Set-IBWAPIConfig -ComputerName $gridmaster -APIVersion 2.2 -Credential (Get-Credential) -IgnoreCertificateValidation $true

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
