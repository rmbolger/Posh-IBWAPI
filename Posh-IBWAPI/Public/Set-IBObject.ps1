function Set-IBObject
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$True)]
        [string]$ObjectRef,
        [Parameter(Mandatory=$True)]
        [hashtable]$Object,
        [string[]]$ReturnFields,
        [switch]$IncludeBasicFields,
        [string]$ComputerName,
        [string]$APIVersion,
        [PSCredential]$Credential,
        [Microsoft.PowerShell.Commands.WebRequestSession]$WebSession,
        [bool]$IgnoreCertificateValidation
    )

    # grab the variables we'll be using for our REST calls
    $common = $ComputerName,$APIVersion,$Credential,$WebSession
    if ($PSBoundParameters.ContainsKey('IgnoreCertificateValidation')) { $common += $IgnoreCertificateValidation }
    $cfg = Initialize-CallVars @common

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

    Invoke-IBWAPI -Method Put -Uri "$($cfg.APIBase)$($ObjectRef)$($querystring)" -Body $bodyJson -WebSession $cfg.WebSession -ContentType 'application/json' -IgnoreCertificateValidation $cfg.IgnoreCertificateValidation

}