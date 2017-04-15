function New-IBObject
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$True)]
        [Alias('type')]
        [string]$ObjectType,
        [Parameter(Mandatory=$True)]
        [PSObject]$Object,
        [Alias('fields')]
        [string[]]$ReturnFields,
        [Alias('base')]
        [switch]$ReturnBaseFields,
        [Alias('host')]
        [string]$WAPIHost,
        [Alias('version')]
        [string]$WAPIVersion,
        [PSCredential]$Credential,
        [Alias('session')]
        [Microsoft.PowerShell.Commands.WebRequestSession]$WebSession,
        [bool]$IgnoreCertificateValidation
    )

    # grab the variables we'll be using for our REST calls
    $common = $WAPIHost,$WAPIVersion,$Credential,$WebSession
    if ($PSBoundParameters.ContainsKey('IgnoreCertificateValidation')) { $common += $IgnoreCertificateValidation }
    $cfg = Initialize-CallVars @common

    $querystring = [String]::Empty

    # process the return fields
    if ($ReturnFields.Count -gt 0) {
        if ($ReturnBaseFields) {
            $querystring = "?_return_fields%2B=$($ReturnFields -join ',')"
        }
        else {
            $querystring = "?_return_fields=$($ReturnFields -join ',')"
        }
    }
    elseif ($ReturnBaseFields) {
        $querystring = "?_return_fields%2B"
    }

    $bodyJson = $Object | ConvertTo-Json -Compress

    Invoke-IBWAPI -Method Post -Uri "$($cfg.APIBase)$($ObjectType)$($querystring)" -Body $bodyJson -WebSession $cfg.WebSession -IgnoreCertificateValidation $cfg.IgnoreCertificateValidation




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
        The set of fields that should be returned in addition to the object reference.

    .PARAMETER ReturnBaseFields
        If specified, the standard fields for this object type will be returned in addition to the object reference and any additional fields specified by -ReturnFields.

    .PARAMETER WAPIHost
        The fully qualified DNS name or IP address of the Infoblox WAPI endpoint (usually the grid master). This parameter is required if not already set using Set-IBWAPIConfig.

    .PARAMETER WAPIVersion
        The version of the Infoblox WAPI to make calls against (e.g. '2.2').

    .PARAMETER Credential
        Username and password for the Infoblox appliance. This parameter is required unless -WebSession is specified or was already set using Set-IBWAPIConfig.

    .PARAMETER WebSession
        A WebRequestSession object returned by Get-IBSession or set when using Invoke-IBWAPI with the -SessionVariable parameter. This parameter is required unless -Credential is specified or was already set using Set-IBWAPIConfig.

    .PARAMETER IgnoreCertificateValidation
        If $true, SSL/TLS certificate validation will be disabled.

    .OUTPUTS
        The object reference string of the created item or a custom object if -ReturnFields or -ReturnBaseFields was used.

    .EXAMPLE
        $mynetwork = @{network='10.10.12.0/24';comment='my network'}
        PS C:\>New-IBObject -ObjectType 'network' -Object $mynetwork

        Create a basic new network with a comment.

    .EXAMPLE
        $myhost = @{name='myhost';comment='my host';configure_for_dns=$false}
        PS C:\>$myhost.ipv4addrs = @(@{ipv4addr='func:nextavailableip:10.10.12.0/24'})
        PS C:\>New-IBObject 'record:host' $myhost -ReturnFields 'comment','configure_for_dns' -ReturnBaseFields

        Create a new host record using an embedded function to get the next available IP in the specified network. Returns the basic host fields plus the comment and configure_for_dns fields.

    .LINK
        Project: https://github.com/rmbolger/Posh-IBWAPI

    .LINK
        Get-IBObject

    #>
}