function Get-IBObject
{

    [CmdletBinding()]
    param(
        [string]$ObjectName,
        [string]$ApiBase,
        [PSCredential]$Credential,
        [string[]]$SearchFilters,
        [string[]]$ReturnFields,
        [switch]$IncludeBasicFields,
        [int]$MaxResults=[int]::MaxValue,
        [switch]$ProxySearch
    )

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
            $response = Invoke-IBWAPI -uri "$ApiBase/$($ObjectName)$($querystring)" -cred $Credential -ContentType 'application/json'
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
        Invoke-IBWAPI -uri "$ApiBase/$($ObjectName)?$($queryargs -join '&')" -cred $Credential -ContentType 'application/json'
    }


}
