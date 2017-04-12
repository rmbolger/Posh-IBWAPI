function Remove-IBObject
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$True)]
        [string]$ObjectRef,
        [string]$ComputerName,
        [string]$APIVersion,
        [PSCredential]$Credential,
        [Microsoft.PowerShell.Commands.WebRequestSession]$WebSession
    )

    # grab the variables we'll be using for our REST calls
    $cfg = Initialize-CallVars $ComputerName $APIVersion $Credential $WebSession

    Invoke-IBWAPI -Method Delete -Uri "$($cfg.APIBase)$($ObjectRef)" -WebSession $cfg.WebSession -ContentType 'application/json'

}