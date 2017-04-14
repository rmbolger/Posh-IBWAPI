function Get-IBObject
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$True)]
        [string]$ObjectName,
        [string[]]$SearchFilters,
        [string[]]$ReturnFields,
        [switch]$IncludeBasicFields,
        [int]$MaxResults=[int]::MaxValue,
        [switch]$ProxySearch,
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

    $queryargs = @()

    # process the search fields
    if ($SearchFilters.Count -gt 0) {
        $queryargs += $SearchFilters
    }

    # process the return fields
    if ($ReturnFields.Count -gt 0) {
        if ($IncludeBasicFields) {
            $queryargs += "_return_fields%2B=$($ReturnFields -join ',')"
        }
        else {
            $queryargs += "_return_fields=$($ReturnFields -join ',')"
        }
    }

    # deal with ProxySearch flag (defaults to LOCAL)
    if ($ProxySearch) {
        $queryargs += "_proxy_search=GM"
    }

    # Normally, we want to automatically page our results. But paging is not allowed
    # when specifying a specific object reference. So we need to determine whether
    # $ObjectName is a specific object reference or not. For now, we're just going
    # to assume anything with a '/' is an object ref. But we might need to get more
    # fancy with regex if this proves to be a problem.
    $DoPaging = ($ObjectName -notlike '*/*')

    if ($DoPaging) {

        # By default, the WAPI will return an error if the result count exceeds 1000
        # unless you make multiple calls using paging. We want to remove this
        # limitation by automatically paging on behalf of the caller. This will also
        # allow the MaxResults parameter in this function to be arbitrarily large (within
        # the bounds of Int32) and not capped at 1000.
        $i = 0
        $results = @()
        do {
            $i++
            Write-Verbose "Fetching page $i"
            $querystring = "?_paging=1&_return_as_object=1&_max_results=1000"
            if ($queryargs.Count -gt 0) {
                $querystring += "&$($queryargs -join '&')"
            }
            if ($i -gt 1) {
                $querystring = "?_page_id=$($response.next_page_id)"
            }
            $response = Invoke-IBWAPI -uri "$($cfg.APIBase)$($ObjectName)$($querystring)" -WebSession $cfg.WebSession -IgnoreCertificateValidation $cfg.IgnoreCertificateValidation
            $results += $response.result
        } while ($response.next_page_id -and $results.Count -lt [Math]::Abs($MaxResults))

        # Throw an error if they specified a negative MaxResults value and the result
        # count exceeds that value. Otherwise, just truncate the results to the MaxResults
        # value. This is basically copying how the _max_results query string argument works.
        if ($MaxResults -lt 0 -and $results.Count -gt [Math]::Abs($MaxResults)) {
            throw [Exception] "Result count exceeded MaxResults parameter."
        }
        else {
            $results | Select-Object -first $MaxResults
        }

    }
    else {
        # no paging, just a single query
        Invoke-IBWAPI -uri "$($cfg.APIBase)$($ObjectName)?$($queryargs -join '&')" -WebSession $cfg.WebSession -IgnoreCertificateValidation $cfg.IgnoreCertificateValidation
    }




    <#
    .SYNOPSIS
        Search for or read specific objects in Infoblox.

    .DESCRIPTION
        There are two ways to use this function. You can get a single object's details by querying its object reference. You can also search for a set of objects based on their metadata using search filters. For large result sets, this function will automatically use query pagination to fetch all results. The maximum result quantity is only limited by the -MaxValue parameter.

    .PARAMETER ObjectName
        Either an object reference string (e.g. record:host/XxXxXxXxXxXxXxX) or an object type string (e.g. record:host).

    .PARAMETER SearchFilters
        An array of search filter conditions. (e.g. "name~=myhost","ipv4addr=10.10.10.10") Only usable when specifying an object type for -ObjectName. All conditions must be satisfied to match an object. See Infoblox WAPI documentation for advanced usage details.

    .PARAMETER ReturnFields
        The set of fields that should be returned in addition to the object reference.

    .PARAMETER IncludeBasicFields
        If specified, the standard fields for this object type will be returned in addition to the object reference and any additional fields specified by -ReturnFields. If -ReturnFields is not used, this defaults to $true.

    .PARAMETER MaxResults
        If set to a positive number, the results list will be truncated to that number if necessary. If set to a negative number and the results would exceed the absolute value, an error is thrown.

    .PARAMETER ComputerName
        The fully qualified DNS name or IP address of the Infoblox WAPI endpoint (usually the grid master). This parameter is required if not already set using Set-IBWAPIConfig.

    .PARAMETER APIVersion
        The version of the Infoblox WAPI to make calls against (e.g. '2.2'). This parameter is required if not already set using Set-IBWAPIConfig.

    .PARAMETER Credential
        Username and password for the Infoblox appliance. This parameter is required unless -WebSession is specified or was already set using Set-IBWAPIConfig.

    .PARAMETER WebSession
        A WebRequestSession object returned by Get-IBSession or set when using Invoke-IBWAPI with the -SessionVariable parameter. This parameter is required unless -Credential is specified or was already set using Set-IBWAPIConfig.

    .PARAMETER IgnoreCertificateValidation
        If $true, SSL/TLS certificate validation will be disabled.

    .OUTPUTS
        Zero or more objects found by the search or object reference. If an object reference is specified that doesn't exist, an error will be thrown.

    .EXAMPLE
        Get-IBObject -ObjectName 'record:host/XxXxXxXxXxXxXxX'

        Get the basic fields for a specific Host record.

    .EXAMPLE
        Get-IBObject 'record:a' -SearchFilters 'name~=.*\.example.com' -MaxResults 100 -ReturnFields 'comment' -IncludeBasicFields

        Get the first 100 A records in the example.com DNS zone and return the comment field in addition to the basic fields.

    .LINK
        Project: https://github.com/rmbolger/Posh-IBWAPI

    .LINK
        Get-IBObject

    #>
}
