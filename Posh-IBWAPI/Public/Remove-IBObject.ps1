function Remove-IBObject
{
    [CmdletBinding()]
    param(
        [string]$ObjectRef,
        [string]$ApiBase,
        [PSCredential]$Credential
    )

    Invoke-IBWAPI -Uri "$ApiBase/$($ObjectRef)" -cred $Credential -Method Delete -ContentType 'application/json'

}