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
        [switch]$IgnoreCertificateValidation
    )

    # Rather than putting this logic in every function that uses it,
    # we'll consolidate it in a private function here that everything
    # else can use.

    # We're essentially building an $APIBase and $WebSession object
    # out of the existing saved module variables and the explicit
    # parameters from the function call. Explicit parameters always
    # override saved module variables.

    # let the saved module variables pass through if explicit the
    # explicit parameters are not defined
    if ([String]::IsNullOrWhiteSpace($WAPIHost)) {
        $WAPIHost = $script:WAPIHost
    }
    if ([String]::IsNullOrWhiteSpace($WAPIVersion)) {
        $WAPIVersion = $script:WAPIVersion
    }
    else {
        # sanity check the version string

        # strip the 'v' prefix if they used it on accident
        if ($WAPIVersion[0] -eq 'v') {
            $WAPIVersion = $WAPIVersion.Substring(1)
        }

        # auto-parse it using the [Version] cast
        [Version]$WAPIVersion | Out-Null
    }
    if (!$Credential) {
        $Credential = $script:Credential
    }
    if (!$WebSession) {
        $WebSession = $script:WebSession
    }

    # build the APIBase URL
    $APIBase = "https://$WAPIHost/wapi/v$WAPIVersion/"

    # build a valid WebSession
    if ($WebSession) {
        if ($Credential) {
            # override the credential embedded in the existing WebSession
            # if it's empty or doesn't match the username
            if (!($WebSession.Credentials -and 
                $WebSession.Credentials.UserName -eq $Credential.GetNetworkCredential().UserName)) {
                Write-Verbose "overriding WebSession.Credentials"
                $WebSession.Credentials = $Credential.GetNetworkCredential()
            }
        }
    }
    elseif ($Credential) {
        # create a WebSession with the specified credential
        $WebSession = New-Object Microsoft.PowerShell.Commands.WebRequestSession
        $WebSession.Credentials = $Credential.GetNetworkCredential()
    }
    else {
        # the caller hasn't defined any credential to use, so just create
        # an empty WebSession that will ultimately generate a 401 error.
        $WebSession = New-Object Microsoft.PowerShell.Commands.WebRequestSession
    }

    if ($PSBoundParameters.ContainsKey('IgnoreCertificateValidation')) {
        $certIgnore = $IgnoreCertificateValidation
    }
    else {
        $certIgnore = $script:IgnoreCertificateValidation
    }

    # return the results
    [PSCustomObject]@{
        APIBase=$APIBase;
        WebSession=$WebSession;
        IgnoreCertificateValidation=$certIgnore;
    }
}