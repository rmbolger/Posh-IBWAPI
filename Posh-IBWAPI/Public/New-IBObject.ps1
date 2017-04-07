function New-IBObject
{
    [CmdletBinding()]
    param(
        [string]$ObjectType,
        [hashtable]$Object,
        [string]$ApiBase,
        [PSCredential]$Credential,
        [string[]]$ReturnFields,
        [switch]$IncludeBasicFields
    )

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

    Invoke-IBWAPI -Uri "$ApiBase/$($ObjectType)?$($queryargs -join '&')" -cred $Credential -Method Post -Body $bodyJson -ContentType 'application/json'



}