function Get-IBObject
{
    [CmdletBinding(DefaultParameterSetName='ByType')]
    param(
        [Parameter(ParameterSetName='ByType',Mandatory=$True,Position=0)]
        [Parameter(ParameterSetName='ByTypeNoPaging',Mandatory=$True,Position=0)]
        [Alias('type')]
        [string]$ObjectType,

        [Parameter(ParameterSetName='ByRef',Mandatory=$True,Position=0,ValueFromPipeline=$True,ValueFromPipelineByPropertyName=$True)]
        [Alias('_ref','ref')]
        [string]$ObjectRef,
        [Parameter(ParameterSetName='ByRef')]
        [switch]$BatchMode,

        [Parameter(ParameterSetName='ByType')]
        [Parameter(ParameterSetName='ByTypeNoPaging')]
        [Alias('Filters')]
        [object]$Filter,

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
        [ValidateScript({Test-NonEmptyString $_ -ThrowOnFail})]
        [Alias('host')]
        [string]$WAPIHost,
        [ValidateScript({Test-VersionString $_ -ThrowOnFail})]
        [Alias('version')]
        [string]$WAPIVersion,
        [PSCredential]$Credential,
        [switch]$SkipCertificateCheck,
        [ValidateScript({Test-ValidProfile $_ -ThrowOnFail})]
        [string]$ProfileName
    )

    Begin {
        # grab the variables we'll be using for our REST and sub calls
        try { $opts = Initialize-CallVars @PSBoundParameters } catch { $PsCmdlet.ThrowTerminatingError($_) }
        $subOpts = [hashtable]::new($opts)
        $APIBase = $script:APIBaseTemplate -f $opts.WAPIHost,$opts.WAPIVersion
        $WAPIVersion = $opts.WAPIVersion
        $opts.Remove('WAPIHost') | Out-Null
        $opts.Remove('WAPIVersion') | Out-Null

        $queryargs = [Collections.Generic.List[string]]::new()

        # Filter must be one of:
        #     [string]    like 'name=foo'
        #     [string[]]  like 'name=foo','view=bar'
        #     [hashtable] like @{ 'name~'='foo' }
        # Because filters end up in the URL querystring, they should be properly URL
        # encoded to avoid WAPI misinterpreting what is being asked for. But historically,
        # string based filters are assumed to have been properly URL encoded in advance
        # by the user because if we blindly encoded the input values, the "=" character
        # separating the field name and value would also be encoded and not work.
        # Consider this Regex based filter:
        #     name~=foo\d+
        # The properly URL encoded version of this should be:
        #     name%7E=foo%5Cd%2B
        # The hashtable option was added in 4.0 so that users no longer have to pre-encode
        # their filters. We can blindly encode the key and value pairs individually before
        # joining them with a non-encoded "=".
        if ($Filter) {
            if ($Filter -is [string]) {
                # add as-is
                $queryargs.Add($Filter)
            }
            elseif ($Filter -is [array] -and $Filter[0] -is [string]) {
                # add as-is
                $queryargs.AddRange([string[]]$Filter)
            }
            elseif ($Filter -is [hashtable]) {
                # URL encode the pairs and join with '=' before adding
                $Filter.GetEnumerator().foreach{
                    $queryargs.Add(
                        ('{0}={1}' -f [Web.HttpUtility]::UrlEncode($_.Key),[Web.HttpUtility]::UrlEncode($_.Value))
                    )
                }
            }
            else {
                $PSCmdlet.ThrowTerminatingError([Management.Automation.ErrorRecord]::new(
                    "Filter parameter is not a supported type. Must be string, string array, or hashtable.",
                    $null, [Management.Automation.ErrorCategory]::InvalidData, $null
                ))
            }
        }

        # Process the return field options if there are any and if ReturnAllFields
        # was not specified. ReturnAllFields requires a schema query based on the
        # object type to get the field names. So we'll postpone that work until the
        # Process {} section in case they passed multiple different object types
        # via _ref.
        if (-not $ReturnAllFields -and $ReturnFields.Count -gt 0) {
            if ($ReturnBaseFields) {
                $queryargs.Add("_return_fields%2B=$($ReturnFields -join ',')")
            }
            else {
                $queryargs.Add("_return_fields=$($ReturnFields -join ',')")
            }
        }

        # Make sure we can do schema queries if ReturnAllFields was specified
        if ($ReturnAllFields) {
            # make a basic schema query if a cache for this host doesn't already exist
            if (-not $script:Schemas[$subOpts.WAPIHost]) {
                try { $null = Get-IBSchema @opts }
                catch { $PSCmdlet.ThrowTerminatingError($_) }
            }
        }

        # Deal with ProxySearch flag. From the WAPI docs
        # If set to ‘GM’, the request is redirected to Grid master for processing.
        # If set to ‘LOCAL’, the request is processed locally. This option is applicable
        # only on vConnector grid members. The default is ‘LOCAL’.
        if ($ProxySearch) {
            $queryargs.Add("_proxy_search=GM")
        }

        if ($BatchMode) {
            # create a list to save the objects in
            $deferredObjects = [Collections.Generic.List[PSObject]]::new()
        }
    }

    Process {

        # Determine what object we're querying and whether we're paging
        if ($PsCmdlet.ParameterSetName -like 'ByType*') {
            # ByType
            $queryObj = $ObjectType
            $UsePaging = $true

            if ($NoPaging) {
                $UsePaging = $false
            } elseif ([Version]$WAPIVersion -lt [Version]'1.5') {
                Write-Verbose "Paging not supported for WAPIVersion $WAPIVersion"
                $UsePaging = $false
            }
        } else {
            # ByRef
            $queryObj = $ObjectRef
            # paging not supported on objref queries
            $UsePaging = $false

            if ($BatchMode) {
                $deferredObjects.Add(@{ object = $ObjectRef })
            }
        }

        # deal with -ReturnAllFields now
        if ($ReturnAllFields) {
            # Returning all fields requires doing a schema query against the object
            # type so we can compile the list of fields to request.
            $oType = $queryObj
            if ($ObjectRef) { $oType = $oType.Substring(0,$oType.IndexOf("/")) }

            $readFields = Get-ReadFieldsForType -ObjectType $oType @subOpts

            if ($BatchMode) {
                $deferredObjects[-1].args = @{
                    '_return_fields' = $readFields -join ','
                }
            } else {
                $queryargs.Add("_return_fields=$($readFields -join ',')")
            }
        }

        if ($BatchMode) {
            # everything else is deferred to End{}, so just return
            return
        }

        # if we're not paging, just return the single call
        if (-not $UsePaging) {
            $uri = "$APIBase$($queryObj)?$($queryargs -join '&')"
            return (Invoke-IBWAPI -Uri $uri @opts)
        }

        # By default, the WAPI will return an error if the result count exceeds 1000
        # unless you make multiple calls using paging. We want to remove this
        # limitation by automatically paging on behalf of the caller. This will also
        # allow the MaxResults parameter in this function to be arbitrarily large
        # (within the bounds of Int32) and not capped at 1000 like a normal WAPI call.

        # separate the MaxResults value from the caller's request to error on "over max"
        $ErrorOverMax = $false
        if ($MaxResults -lt 0) {
            $MaxResults = [Math]::Abs($MaxResults)
            $ErrorOverMax = $true
        }

        # make sure the $PageSize is never more than 1 over $MaxResults so we don't
        # retrieve more data than necessary but "over max" errors will still trigger
        if ($MaxResults -lt $PageSize -and $MaxResults -lt 1000) {
            $PageSize = $MaxResults + 1
        }

        $querystring = "?_paging=1&_return_as_object=1&_max_results=$PageSize"
        if ($queryargs.Count -gt 0) {
            $querystring += "&$($queryargs -join '&')"
        }
        $pageNum = 0
        $resultCount = 0
        $results = do {
            $pageNum++
            Write-Verbose "Fetching page $pageNum"
            if ($pageNum -gt 1) {
                $querystring = "?_page_id=$($response.next_page_id)"
            }

            $uri = "$APIBase$($queryObj)$($querystring)"

            $response = Invoke-IBWAPI -Uri $uri @opts
            if ('result' -notin $response.PSObject.Properties.Name) {
                # A normal response from WAPI will contain a 'result' object even
                # if that object is empty because it couldn't find anything.
                # But if there's no result object, something is wrong.
                $PSCmdlet.ThrowTerminatingError([Management.Automation.ErrorRecord]::new(
                    "No 'result' object found in server response",
                    $null, [Management.Automation.ErrorCategory]::InvalidData, $null
                ))
            }
            $resultCount += $response.result.Count
            $response.result

        } while ($response.next_page_id -and $resultCount -lt $MaxResults)

        # Error if they specified a negative MaxResults value and the result
        # count exceeds that value. Otherwise, just truncate the results to the MaxResults
        # value. This is basically copying how the _max_results query string argument works.
        if ($ErrorOverMax -and $resultCount -gt $MaxResults) {
            $PSCmdlet.WriteError([Management.Automation.ErrorRecord]::new(
                "Result count exceeded MaxResults parameter.",
                $null, [Management.Automation.ErrorCategory]::InvalidData, $null
            ))
        }
        else {
            $results | Select-Object -First $MaxResults
        }

    }

    End {
        if (-not $BatchMode -or $deferredObjects.Count -eq 0) { return }
        Write-Verbose "BatchMode deferred objects: $($deferredObjects.Count)"

        # build the 'args' value for each object
        $retArgs = @{}
        if ($ReturnFields.Count -gt 0) {
            if ($ReturnBaseFields) {
                $retArgs.'_return_fields+' = $ReturnFields -join ','
            } else {
                $retArgs.'_return_fields'  = $ReturnFields -join ','
            }
        } else {
            $retArgs.'_return_fields+' = ''
        }

        # build the json for all the objects
        $body = $deferredObjects | ForEach-Object {
            @{
                method = 'GET'
                object = $_.object
                args = if ($_.args) { $_.args } else { $retArgs }
            }
        }

        $uri = '{0}request' -f $APIBase
        Invoke-IBWAPI -Method Post -Uri $uri -Body $body @opts
    }



    <#
    .SYNOPSIS
        Retrieve objects from the Infoblox database.

    .DESCRIPTION
        Query a specific object's details by specifying ObjectRef or search for a set of objects using ObjectType and optional Filter arguments. For large result sets, query pagination will automatically be used to fetch all results. The result count can be limited with the -MaxResults parameter.

    .PARAMETER ObjectRef
        Object reference string. This is usually found in the "_ref" field of returned objects.

    .PARAMETER ObjectType
        Object type string. (e.g. network, record:host, range)

    .PARAMETER BatchMode
        If specified, objects passed via pipeline will be batched together into groups and sent as a single WAPI call per group instead of a WAPI call per object. This can increase performance but if any of the individual calls fail, the whole group is cancelled.

    .PARAMETER Filter
        A string array of search filter conditions (e.g. "name%7E=myhost","ipv4addr=10.10.10.10") or hashtable (e.g. @{'name~'='myhost';ipv4addr='10.10.10.10'}). All conditions must be satisfied to match an object. String based filters must be properly URL encoded. Hashtable filters will be automatically URL encoded. See Infoblox WAPI documentation for advanced usage details.

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
        Username and password for the Infoblox appliance. This parameter is required unless it was already set using Set-IBConfig.

    .PARAMETER SkipCertificateCheck
        If set, SSL/TLS certificate validation will be disabled. Overrides value stored with Set-IBConfig.

    .OUTPUTS
        Zero or more objects found by the search or object reference. If an object reference is specified that doesn't exist, an error will be thrown.

    .EXAMPLE
        Get-IBObject -ObjectRef 'record:host/XxXxXxXxXxXxXxX'

        Get the basic fields for a specific Host record.

    .EXAMPLE
        Get-IBObject 'record:a' -Filter 'name~=.*\.example.com' -MaxResults 100 -ReturnFields 'comment' -ReturnBaseFields

        Get the first 100 A records in the example.com DNS zone and return the comment field in addition to the basic fields.

    .EXAMPLE
        Get-IBObject -ObjectType 'networkcontainer' -Filter 'network_container=192.168.1.0/19'

        Get all network containers that have a parent container of 192.168.1.0/19

    .EXAMPLE
        Get-IBObject -ObjectType 'network' -Filter 'network_container=192.168.1.0/20'

        Get all networks that have a parent container of 192.168.1.0/20

    .LINK
        Project: https://github.com/rmbolger/Posh-IBWAPI

    .LINK
        Set-IBConfig

    #>
}
