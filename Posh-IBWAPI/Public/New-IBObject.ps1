function New-IBObject
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$True)]
        [string]$ObjectType,
        [Parameter(Mandatory=$True)]
        [hashtable]$Object,
        [string[]]$ReturnFields,
        [switch]$IncludeBasicFields,
        [string]$ComputerName,
        [string]$APIVersion,
        [PSCredential]$Credential,
        [Microsoft.PowerShell.Commands.WebRequestSession]$WebSession
    )

    # grab the variables we'll be using for our REST calls
    $cfg = Initialize-CallVars $ComputerName $APIVersion $Credential $WebSession

    $querystring = [String]::Empty

    # process the return fields
    if ($ReturnFields.Count -gt 0) {
        if ($IncludeBasicFields) {
            $querystring = "?_return_fields%2B=$($ReturnFields -join ',')"
        }
        else {
            $querystring = "?_return_fields=$($ReturnFields -join ',')"
        }
    }

    $bodyJson = $Object | ConvertTo-Json -Compress

    Invoke-IBWAPI -Method Post -Uri "$($cfg.APIBase)$($ObjectType)$($querystring)" -Body $bodyJson -WebSession $cfg.WebSession -ContentType 'application/json'



}