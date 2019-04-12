function Get-IBObject
{
    [CmdletBinding(SupportsShouldProcess,DefaultParameterSetName='ByType')]
    param(
        [Parameter(ParameterSetName='ByType',Mandatory=$True,Position=0)]
        [Parameter(ParameterSetName='ByTypeNoPaging',Mandatory=$True,Position=0)]
        [Alias('type')]
        [string]$ObjectType,

        [Parameter(ParameterSetName='ByRef',Mandatory=$True,Position=0,ValueFromPipeline=$True,ValueFromPipelineByPropertyName=$True)]
        [Alias('_ref','ref')]
        [string]$ObjectRef,

        [Parameter(ParameterSetName='ByType')]
        [Parameter(ParameterSetName='ByTypeNoPaging')]
        [string[]]$Filters,

        [Parameter(ParameterSetName='ByType')]
        [int]$MaxResults=[int]::MaxValue,
        [Parameter(ParameterSetName='ByType')]
        [ValidateRange(1,1000)]
        [int]$PageSize=1000,
        [Parameter(ParameterSetName='ByTypeNoPaging')]
        [switch]$NoPaging,

        [Alias('fields')]
        [string[]]$ReturnFields,
        [Alias('base')]
        [switch]$ReturnBaseFields,
        [Alias('all')]
        [switch]$ReturnAllFields,
        [switch]$ProxySearch,
        [Alias('host')]
        [string]$WAPIHost,
        [Alias('version')]
        [string]$WAPIVersion,
        [PSCredential]$Credential,
        [Alias('session')]
        [Microsoft.PowerShell.Commands.WebRequestSession]$WebSession,
        [switch]$SkipCertificateCheck
    )

    Begin {
        # grab the variables we'll be using for our REST calls
        $opts = Initialize-CallVars @PSBoundParameters
        $APIBase = $script:APIBaseTemplate -f $opts.WAPIHost,$opts.WAPIVersion
        $WAPIVersion = $opts.WAPIVersion
        $opts.Remove('WAPIHost') | Out-Null
        $opts.Remove('WAPIVersion') | Out-Null

        $queryargs = @()

        # process the search fields
        if ($Filters.Count -gt 0) {
            $queryargs += $Filters
        }

        # process the return field options
        if ($ReturnAllFields) {
            # Because this requires a schema query based on the object type to get the field
            # names, we're going to postpone this work until the Process {} section in case
            # they passed multiple different object types via _ref.
        } else {
            if ($ReturnFields.Count -gt 0) {
                if ($ReturnBaseFields) {
                    $queryargs += "_return_fields%2B=$($ReturnFields -join ',')"
                }
                else {
                    $queryargs += "_return_fields=$($ReturnFields -join ',')"
                }
            }
        }

        # deal with ProxySearch flag (defaults to LOCAL)
        if ($ProxySearch) {
            $queryargs += "_proxy_search=GM"
        }
    }

    Process {
        # default to using paging
        $UsePaging = $true

        switch ($PsCmdlet.ParameterSetName) {
            'ByRef' {
                # paging not supported on objref queries
                $UsePaging = $false

                $queryObj = $ObjectRef
            }
            'ByType' {
                # WAPI versions older than 1.5 don't support paging
                if ([Version]$WAPIVersion -lt [Version]'1.5') {
                    Write-Verbose "Paging disabled for WAPIVersion $($WAPIVersion)"
                    $UsePaging = $false
                }

                $queryObj = $ObjectType
            }
            'ByTypeNoPaging' {
                $UsePaging = $false
                $queryObj = $ObjectType
            }
        }

        # deal with -ReturnAllFields now
        if ($ReturnAllFields) {
            # Returning all fields requires doing a schema query against the object type first
            # so we can compile the list of fields to request.
            $oType = $queryObj
            if ($ObjectRef) { $oType = $oType.Substring(0,$oType.IndexOf("/")) }

            # Not all WAPI versions support schema queries, so handle appropriately
            try {
                Write-Verbose "Querying schema for $oType fields"
                $schema = Get-IBSchema $oType -Raw
            } catch {
                if ($_ -like "*doesn't support schema queries*") {
                    throw "The -ReturnAllFields parameter requires querying the schema and $_"
                } else { throw }
            }

            # grab the readable fields and add them to the querystring
            $readFields = ($schema.fields | Where-Object { $_.supports -like '*r*' -and $_.wapi_primitive -ne 'funccall' }).name
            $queryargs += "_return_fields=$($readFields -join ',')"
        }

        if ($UsePaging) {
            # By default, the WAPI will return an error if the result count exceeds 1000
            # unless you make multiple calls using paging. We want to remove this
            # limitation by automatically paging on behalf of the caller. This will also
            # allow the MaxResults parameter in this function to be arbitrarily large (within
            # the bounds of Int32) and not capped at 1000.

            # separate the MaxResults value from the caller's request to error on "over max"
            $ErrorOverMax = $false
            if ($MaxResults -lt 0) {
                $MaxResults = [Math]::Abs($MaxResults)
                $ErrorOverMax = $true
            }

            # make sure the $PageSize is never more than 1 over $MaxResults so we don't
            # retrieve more data than necessary but "over max" errors will still trigger
            if ($MaxResults -lt $PageSize -and $MaxResults -lt 1000) { $PageSize = ($MaxResults+1) }

            $i = 0
            $results = @()
            $querystring = "?_paging=1&_return_as_object=1&_max_results=$PageSize"
            if ($queryargs.Count -gt 0) {
                $querystring += "&$($queryargs -join '&')"
            }
            do {
                $i++
                Write-Verbose "Fetching page $i"
                if ($i -gt 1) {
                    $querystring = "?_page_id=$($response.next_page_id)"
                }

                $uri = "$APIBase$($queryObj)$($querystring)"

                if ($PsCmdlet.ShouldProcess($uri, 'GET')) {
                    $response = Invoke-IBWAPI -Uri $uri @opts
                    if ($response.PSObject.Properties.Name -notcontains "result") {
                        # A normal response from WAPI will contain a 'result' object even
                        # if that object is empty because it couldn't find anything.
                        # But if there's no result object, something is wrong.
                        throw "No 'result' object found in server response"
                    }
                    $results += $response.result
                }
            } while ($response.next_page_id -and $results.Count -lt $MaxResults)

            # Throw an error if they specified a negative MaxResults value and the result
            # count exceeds that value. Otherwise, just truncate the results to the MaxResults
            # value. This is basically copying how the _max_results query string argument works.
            if ($ErrorOverMax -and $results.Count -gt $MaxResults) {
                throw [Exception] "Result count exceeded MaxResults parameter."
            }
            else {
                $results | Select-Object -first $MaxResults
            }
        }
        else {
            # no paging, just a single query on the object reference
            $uri = "$APIBase$($queryObj)?$($queryargs -join '&')"

            if ($PsCmdlet.ShouldProcess($uri, 'GET')) {
                Invoke-IBWAPI -Uri $uri @opts
            }
        }

    }




    <#
    .SYNOPSIS
        Retrieve objects from the Infoblox database.

    .DESCRIPTION
        Query a specific object's details by specifying ObjectRef or search for a set of objects using ObjectType and optionall Filters. For large result sets, query pagination will automatically be used to fetch all results. The result count can be limited with the -MaxResults parameter.

    .PARAMETER ObjectRef
        Object reference string. This is usually found in the "_ref" field of returned objects.

    .PARAMETER ObjectType
        Object type string. (e.g. network, record:host, range)

    .PARAMETER Filters
        An array of search filter conditions. (e.g. "name~=myhost","ipv4addr=10.10.10.10"). All conditions must be satisfied to match an object. See Infoblox WAPI documentation for advanced usage details.

    .PARAMETER MaxResults
        If set to a positive number, the results list will be truncated to that number if necessary. If set to a negative number and the results would exceed the absolute value, an error is thrown.

    .PARAMETER PageSize
        The number of results to retrieve per request when auto-paging large result sets. Defaults to 1000. Set this lower if you have very large results that are causing errors with ConvertTo-Json.

    .PARAMETER NoPaging
        If specified, automatic paging will not be used. This is occasionally necessary for some object type queries that return a single object reference such as dhcp:statistics.

    .PARAMETER ReturnFields
        The set of fields that should be returned in addition to the object reference.

    .PARAMETER ReturnBaseFields
        If specified, the standard fields for this object type will be returned in addition to the object reference and any additional fields specified by -ReturnFields. If -ReturnFields is not used, this defaults to $true.

    .PARAMETER ReturnAllFields
        If specified, all readable fields will be returned for the object. This switch relies on Get-IBSchema and as such requires WAPI 1.7.5+. Because of the additional web requests necessary to make this work, it is also not recommended for performance critical code.

    .PARAMETER WAPIHost
        The fully qualified DNS name or IP address of the Infoblox WAPI endpoint (usually the grid master). This parameter is required if not already set using Set-IBConfig.

    .PARAMETER WAPIVersion
        The version of the Infoblox WAPI to make calls against (e.g. '2.2'). This parameter is required if not already set using Set-IBConfig.

    .PARAMETER Credential
        Username and password for the Infoblox appliance. This parameter is required unless -WebSession is specified or was already set using Set-IBConfig.

    .PARAMETER WebSession
        A WebRequestSession object returned by Get-IBSession or set when using Invoke-IBWAPI with the -SessionVariable parameter. This parameter is required unless -Credential is specified or was already set using Set-IBConfig.

    .PARAMETER SkipCertificateCheck
        If set, SSL/TLS certificate validation will be disabled. Overrides value stored with Set-IBConfig.

    .OUTPUTS
        Zero or more objects found by the search or object reference. If an object reference is specified that doesn't exist, an error will be thrown.

    .EXAMPLE
        Get-IBObject -ObjectRef 'record:host/XxXxXxXxXxXxXxX'

        Get the basic fields for a specific Host record.

    .EXAMPLE
        Get-IBObject 'record:a' -Filters 'name~=.*\.example.com' -MaxResults 100 -ReturnFields 'comment' -ReturnBaseFields

        Get the first 100 A records in the example.com DNS zone and return the comment field in addition to the basic fields.

    .LINK
        Project: https://github.com/rmbolger/Posh-IBWAPI

    .LINK
        Set-IBConfig

    #>
}
