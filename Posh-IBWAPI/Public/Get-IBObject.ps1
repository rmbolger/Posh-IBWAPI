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
        [Alias('base','ReturnBaseFields')]
        [switch]$ReturnBase,
        [Alias('all','ReturnAllFields')]
        [switch]$ReturnAll,

        [Parameter(ParameterSetName='ByRef')]
        [switch]$BatchMode,
        [Parameter(ParameterSetName='ByRef')]
        [ValidateRange(1,2147483647)]
        [int]$BatchGroupSize = 1000,

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

        $queryargs = [Collections.Generic.List[string]]::new()

        # Filter must be one of:
        #     [string]      like 'name=foo'
        #     [string[]]    like 'name=foo','view=bar'
        #     [IDictionary] like @{ 'name~'='foo' }
        # Because filters end up in the URL querystring, they should be properly URL
        # encoded to avoid WAPI misinterpreting what is being asked for. But historically,
        # string based filters are assumed to have been properly URL encoded in advance
        # by the user because if we blindly encoded the input values, the "=" character
        # separating the field name and value would also be encoded and not work.
        # Consider this Regex based filter:
        #     name~=foo\d+
        # The properly URL encoded version of this should be:
        #     name%7E=foo%5Cd%2B
        # The IDictionary option was added in 4.0 so that users no longer have to pre-encode
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
            elseif ($Filter -is [Collections.IDictionary]) {
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
                    $null, [Management.Automation.ErrorCategory]::InvalidArgument, $null
                ))
            }
        }

        # Process the return field options if there are any and if ReturnAll
        # was not specified. ReturnAll requires a schema query based on the
        # object type to get the field names. So we'll postpone that work until the
        # Process {} section in case they passed multiple different object types
        # via _ref.
        if (-not $ReturnAll -and $ReturnFields.Count -gt 0) {
            if ($ReturnBase) {
                $queryargs.Add("_return_fields%2B=$($ReturnFields -join ',')")
            }
            else {
                $queryargs.Add("_return_fields=$($ReturnFields -join ',')")
            }
        }

        # Make sure we can do schema queries if ReturnAll was specified
        if ($ReturnAll) {
            # make a basic schema query if a cache for this host doesn't already exist
            if (-not $script:Schemas[$opts.WAPIHost]) {
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
            } elseif ([Version]$opts.WAPIVersion -lt [Version]'1.5') {
                Write-Verbose "Paging not supported for WAPIVersion $($opts.WAPIVersion)"
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

        # deal with -ReturnAll now
        if ($ReturnAll) {
            # Returning all fields requires doing a schema query against the object
            # type so we can compile the list of fields to request.
            $oType = $queryObj
            if ($ObjectRef) { $oType = $oType.Substring(0,$oType.IndexOf("/")) }

            $readFields = Get-ReadFieldsForType -ObjectType $oType @opts

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
            $query = '{0}?{1}' -f $queryObj,($queryargs -join '&')
            return (Invoke-IBWAPI -Query $query @opts)
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

            $query = '{0}{1}' -f $queryObj,$querystring

            $response = Invoke-IBWAPI -Query $query @opts
            if ('result' -notin $response.PSObject.Properties.Name) {
                # A normal response from WAPI will contain a 'result' object even
                # if that object is empty because it couldn't find anything.
                # But if there's no result object, something is wrong.
                $PSCmdlet.ThrowTerminatingError([Management.Automation.ErrorRecord]::new(
                    "No 'result' object found in server response",
                    $null, [Management.Automation.ErrorCategory]::ObjectNotFound, $null
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
                $null, [Management.Automation.ErrorCategory]::LimitsExceeded, $null
            ))
        }
        else {
            $results | Select-Object -First $MaxResults
        }

    }

    End {
        if (-not $BatchMode -or $deferredObjects.Count -eq 0) { return }
        Write-Verbose "BatchMode deferred objects: $($deferredObjects.Count), group size $($BatchGroupSize)"

        # build the 'args' value for each object
        $retArgs = @{}
        if ($ReturnFields.Count -gt 0) {
            if ($ReturnBase) {
                $retArgs.'_return_fields+' = $ReturnFields -join ','
            } else {
                $retArgs.'_return_fields'  = $ReturnFields -join ','
            }
        } else {
            $retArgs.'_return_fields+' = ''
        }

        # make calls based on the group size
        for ($i=0; $i -lt $deferredObjects.Count; $i += $BatchGroupSize) {
            $groupEnd = [Math]::Min($deferredObjects.Count, ($i+$BatchGroupSize-1))

            # build the json for this group's objects
            $body = $deferredObjects[$i..$groupEnd] | ForEach-Object {
                @{
                    method = 'GET'
                    object = $_.object
                    args = if ($_.args) { $_.args } else { $retArgs }
                }
            }

            Invoke-IBWAPI -Query 'request' -Method 'POST' -Body $body @opts
        }

    }
}
