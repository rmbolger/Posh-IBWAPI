function Set-IBObject
{
    [CmdletBinding()]
    param(
        [string]$ObjectRef,
        [hashtable]$Object,
        [string]$ApiBase,
        [PSCredential]$Credential,
        [Microsoft.PowerShell.Commands.WebRequestSession]$WebSession,
        [string[]]$ReturnFields,
        [switch]$IncludeBasicFields
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

    $queryargs = @()

    # process the return fields
    if ($ReturnFields.Count -gt 0) {
        if ($IncludeBasicFields) {
            $queryargs += "_return_fields%2B=$($ReturnFields -join ',')"
        }
        else {
            $queryargs += "_return_fields=$($ReturnFields -join ',')"
        }
    }

    $bodyJson = $Object | ConvertTo-Json -Compress

    Invoke-IBWAPI -Method Put -Uri "$ApiBase/$($ObjectRef)?$($queryargs -join '&')" -Body $bodyJson -WebSession $WebSession -ContentType 'application/json'

}