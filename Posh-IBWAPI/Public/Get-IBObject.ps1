function Get-IBObject
{
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(ParameterSetName='ByRef',Mandatory=$True,Position=0,ValueFromPipeline=$True,ValueFromPipelineByPropertyName=$True)]
        [Alias('_ref','ref')]
        [string[]]$ObjectRef,

        [Parameter(ParameterSetName='ByType',Mandatory=$True,Position=0)]
        [Alias('type')]
        [string]$ObjectType,

        [Parameter(ParameterSetName='ByType')]
        [string[]]$Filters,

        [Parameter(ParameterSetName='ByType')]
        [int]$MaxResults=[int]::MaxValue,

        [Parameter(ParameterSetName='ByRef')]
        [Parameter(ParameterSetName='ByType')]
        [Alias('fields')]
        [string[]]$ReturnFields,
        [Parameter(ParameterSetName='ByRef')]
        [Parameter(ParameterSetName='ByType')]
        [Alias('base')]
        [switch]$ReturnBaseFields,
        [Parameter(ParameterSetName='ByRef')]
        [Parameter(ParameterSetName='ByType')]
        [Alias('all')]
        [switch]$ReturnAllFields,
        [Parameter(ParameterSetName='ByRef')]
        [Parameter(ParameterSetName='ByType')]
        [switch]$ProxySearch,
        [Parameter(ParameterSetName='ByRef')]
        [Parameter(ParameterSetName='ByType')]
        [Alias('host')]
        [string]$WAPIHost,
        [Parameter(ParameterSetName='ByRef')]
        [Parameter(ParameterSetName='ByType')]
        [Alias('version')]
        [string]$WAPIVersion,
        [Parameter(ParameterSetName='ByRef')]
        [Parameter(ParameterSetName='ByType')]
        [PSCredential]$Credential,
        [Parameter(ParameterSetName='ByRef')]
        [Parameter(ParameterSetName='ByType')]
        [Alias('session')]
        [Microsoft.PowerShell.Commands.WebRequestSession]$WebSession,
        [Parameter(ParameterSetName='ByRef')]
        [Parameter(ParameterSetName='ByType')]
        [switch]$IgnoreCertificateValidation
    )

    Begin {
        # grab the variables we'll be using for our REST calls
        $opts = Initialize-CallVars @PSBoundParameters
        $APIBase = Base @opts
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
            "ByRef" {
                # paging not supported on objref queries
                $UsePaging = $false

                $queryObj = $ObjectRef
            }
            "ByType" {
                # WAPI versions older than 1.5 don't support paging
                if ([Version]$WAPIVersion -lt [Version]'1.5') {
                    Write-Verbose "Paging disabled for WAPIVersion $($WAPIVersion)"
                    $UsePaging = $false
                }

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
            $readFields = ($schema.fields | ?{ $_.supports -like '*r*' -and $_.wapi_primitive -ne 'funccall' }).name
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

            # set the default page size unless the caller wants less, in which case
            # set it to just over what they asked for so that "over max" errors will
            # still trigger
            $pageSize = 1000
            if ($MaxResults -lt $pageSize) { $pageSize = ($MaxResults+1) }

            $i = 0
            $results = @()
            $querystring = "?_paging=1&_return_as_object=1&_max_results=$pageSize"
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

    .PARAMETER ReturnFields
        The set of fields that should be returned in addition to the object reference.

    .PARAMETER ReturnBaseFields
        If specified, the standard fields for this object type will be returned in addition to the object reference and any additional fields specified by -ReturnFields. If -ReturnFields is not used, this defaults to $true.

    .PARAMETER WAPIHost
        The fully qualified DNS name or IP address of the Infoblox WAPI endpoint (usually the grid master). This parameter is required if not already set using Set-IBWAPIConfig.

    .PARAMETER WAPIVersion
        The version of the Infoblox WAPI to make calls against (e.g. '2.2'). This parameter is required if not already set using Set-IBWAPIConfig.

    .PARAMETER Credential
        Username and password for the Infoblox appliance. This parameter is required unless -WebSession is specified or was already set using Set-IBWAPIConfig.

    .PARAMETER WebSession
        A WebRequestSession object returned by Get-IBSession or set when using Invoke-IBWAPI with the -SessionVariable parameter. This parameter is required unless -Credential is specified or was already set using Set-IBWAPIConfig.

    .PARAMETER IgnoreCertificateValidation
        If set, SSL/TLS certificate validation will be disabled. Overrides value stored with Set-IBWAPIConfig.

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
        Set-IBWAPIConfig

    #>
}
