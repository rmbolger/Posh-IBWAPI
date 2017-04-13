function New-IBObject
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$True)]
        [string]$ObjectType,
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

    Invoke-IBWAPI -Method Post -Uri "$($cfg.APIBase)$($ObjectType)$($querystring)" -Body $bodyJson -WebSession $cfg.WebSession -ContentType 'application/json' -IgnoreCertificateValidation $cfg.IgnoreCertificateValidation




    <#
    .SYNOPSIS
        Create an object in Infoblox.

    .DESCRIPTION
        Create an object by specifying the type and a PSObject with the required (and optional) fields for that type.

    .PARAMETER ObjectType
        Object type string. (e.g. network, record:host, range)

    .PARAMETER Object
        A PSObject with the required fields for the specified type. Optional fields may also be included.

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
        The object reference string of the created item or a custom object if return fields were specified.

    .EXAMPLE
        $mynetwork = @{network='10.10.12.0/24';comment='my network'}
        PS C:\>New-IBObject -ObjectType 'network' -Object $mynetwork

        Create a basic new network with a comment.

    .EXAMPLE
        $myhost = @{name='myhost';comment='my host';configure_for_dns=$false}
        PS C:\>$myhost.ipv4addrs = @(@{ipv4addr='func:nextavailableip:10.10.12.0/24'})
        PS C:\>New-IBObject 'record:host' $myhost -ReturnFields 'comment','configure_for_dns' -IncludeBasicFields

        Create a new host record using an embedded function to get the next available IP in the specified network. Returns the basic host fields plus the comment and configure_for_dns fields.

    .LINK
        Project: https://github.com/rmbolger/Posh-IBWAPI

    .LINK
        Get-IBObject

    #>
}