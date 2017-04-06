function Get-IBObject
{

    [CmdletBinding()]
    param(
        [string]$ObjectName,
        [string]$ApiBase,
        [PSCredential]$Credential,
        [string[]]$ReturnFields,
        [switch]$IncludeBasicFields,
        [int]$MaxResults=[int]::MaxValue
    )

    # process the return fields
    if ($ReturnFields.Count -gt 0) {
        if ($IncludeBasicFields) {
            $querystring += "_return_fields%2B=$($ReturnFields -join ',')"
        }
        else {
            $querystring += "_return_fields=$($ReturnFields -join ',')"
        }
    }

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
        $querystring = "?_paging=1&_return_as_object=1&_max_results=1000&$querystring"
        if ($i -gt 1) {
            $querystring = "?_page_id=$($response.next_page_id)"
        }
        $response = Invoke-IBWAPI -uri "$ApiBase/$($ObjectName)$($querystring)" -cred $Credential -ContentType "application/json"
        $results += $response.result
    } while ($response.next_page_id -and $results.Count -lt [Math]::Abs($MaxResults))

    # Throw an error if they specified a negative MaxResults value and the result
    # count exceeds that value. Otherwise, just truncate the results to the MaxResults
    # value. This is basically copying how the _max_results query string argument works.
    Write-Verbose "$($results.Count) -gt $([Math]::Abs($MaxResults))"
    if ($MaxResults -lt 0 -and $results.Count -gt [Math]::Abs($MaxResults)) {
        throw [Exception] "Result count exceeded MaxResults parameter."
    }
    else {
        $results | Select-Object -first $MaxResults
    }

}
