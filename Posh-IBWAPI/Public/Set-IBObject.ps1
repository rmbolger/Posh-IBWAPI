function Set-IBObject
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$True)]
        [string]$ObjectRef,
        [Parameter(Mandatory=$True)]
        [PSObject]$Object,
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




    <#
    .SYNOPSIS
        Modify an object in Infoblox.

    .DESCRIPTION
        Modify an object by specifying its object reference and a PSObject with the fields to change.

    .PARAMETER ObjectRef
        Object reference string. This is usually found in the "_ref" field of returned objects.

    .PARAMETER Object
        A PSObject with the fields to be modified. All included fields will be modified even if they are empty.

    .PARAMETER ReturnFields
        TODO

    .PARAMETER IncludeBasicFields
        TODO

    .PARAMETER ComputerName
        TODO

    .PARAMETER APIVersion
        TODO

    .PARAMETER Credential
        TODO

    .PARAMETER WebSession
        TODO

    .PARAMETER IgnoreCertificateValidation
        TODO

    .OUTPUTS
        The object reference string of the modified item or a custom object if return fields were specified.

    .EXAMPLE
        $myhost = Get-IBObject -ObjectName 'record:host' -SearchFilters 'name=myhost' -ReturnFields 'comment'
        PS C:\>$myhost.comment = 'new comment'
        PS C:\>Set-IBObject -ObjectRef $myhost._ref -Object $myhost

        Search for a host record called 'myhost', update the comment field, and save it.

    .LINK
        Project: https://github.com/rmbolger/Posh-IBWAPI

    .LINK
        Get-IBObject

    #>
}