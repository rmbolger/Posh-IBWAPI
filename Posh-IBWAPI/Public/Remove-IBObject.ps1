function Remove-IBObject
{
    [CmdletBinding()]
    param(
        [string]$ObjectRef,
        [string]$ApiBase,
        [PSCredential]$Credential,
        [Microsoft.PowerShell.Commands.WebRequestSession]$WebSession
    )

    # To simplify code later, we always want to authenticate using a $WebSession
    # object. So we'll create one if it doesn't exist. We'll also embed/overwrite
    # the Credential parameter (if it exists) into to session object. If neither
    # Credential or WebSession are passed in, the user will get a authentication
    # error from Infoblox. But that's not our problem.
    if (!$WebSession) {
        $WebSession = New-Object Microsoft.PowerShell.Commands.WebRequestSession
    }
    if ($Credential) {
        $WebSession.Credentials = $Credential.GetNetworkCredential()
    }

    Invoke-IBWAPI -Method Delete -Uri "$ApiBase/$($ObjectRef)" -WebSession $WebSession -ContentType 'application/json'

}