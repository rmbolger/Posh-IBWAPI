function Set-IBObject
{
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(ParameterSetName='ObjectOnly',Mandatory=$True,ValueFromPipeline=$True)]
        [PSObject]$IBObject,

        [Parameter(ParameterSetName='RefAndTemplate',Mandatory=$True,ValueFromPipeline=$True,ValueFromPipelineByPropertyName=$True)]
        [Alias('_ref','ref')]
        [string]$ObjectRef,

        [Parameter(ParameterSetName='RefAndTemplate',Mandatory=$True)]
        [PSObject]$TemplateObject,

        [Alias('fields')]
        [string[]]$ReturnFields,
        [Alias('base')]
        [switch]$ReturnBaseFields,
        [switch]$BatchMode,
        [ValidateRange(1,2147483647)]
        [int]$BatchGroupSize = 1000,
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
        # grab the variables we'll be using for our REST calls
        try { $opts = Initialize-CallVars @PSBoundParameters } catch { $PsCmdlet.ThrowTerminatingError($_) }

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

        if ($BatchMode) {
            # create a list to save the objects in
            $deferredObjects = [Collections.Generic.List[PSObject]]::new()
        }
    }

    Process {

        if ($BatchMode) {
            # add the appropriate object to the list for processing during End{}
            if ('ObjectOnly' -eq $PsCmdlet.ParameterSetName) {
                $deferredObjects.Add($IBObject)
            } else {
                $deferredObjects.Add($ObjectRef)
            }
            return
        }

        if ('ObjectOnly' -eq $PsCmdlet.ParameterSetName) {

            # get the ObjectRef from the input object
            if (-not $IBObject._ref) {
                $PSCmdlet.WriteError([Management.Automation.ErrorRecord]::new(
                    "IBObject is missing '_ref' field.", $null, [Management.Automation.ErrorCategory]::InvalidArgument, $null
                ))
                return
            }
            $ObjectRef = $IBObject._ref
            $IBObject.PSObject.Properties.Remove('_ref')

            $TemplateObject = $IBObject
        }

        $query = '{0}{1}' -f $ObjectRef,$querystring
        if ($PsCmdlet.ShouldProcess($opts.WAPIHost, 'PUT')) {
            Invoke-IBWAPI -Query $query -Method 'PUT' -Body $TemplateObject @opts
        }
    }

    End {
        if (-not $BatchMode -or $deferredObjects.Count -eq 0) { return }
        Write-Verbose "BatchMode deferred objects: $($deferredObjects.Count), group size $($BatchGroupSize)"

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

        # make calls based on the group size
        for ($i=0; $i -lt $deferredObjects.Count; $i += $BatchGroupSize) {
            $groupEnd = [Math]::Min($deferredObjects.Count, ($i+$BatchGroupSize-1))

            # build the json for this group's objects
            $body = $deferredObjects[$i..$groupEnd] | ForEach-Object {

                if ('ObjectOnly' -eq $PsCmdlet.ParameterSetName) {

                    # get the ObjectRef from the input object
                    if (-not $_._ref) {
                        $PSCmdlet.WriteError([Management.Automation.ErrorRecord]::new(
                            "IBObject is missing '_ref' field.", $null, [Management.Automation.ErrorCategory]::InvalidArgument, $null
                        ))
                        return
                    }
                    $ObjectRef = $_._ref
                    $_.PSObject.Properties.Remove('_ref')

                    $TemplateObject = $_
                } else {
                    $ObjectRef = $_
                }

                @{
                    method = 'PUT'
                    object = $ObjectRef
                    data = $TemplateObject
                    args = $retArgs
                }
            }

            if (-not $body) {
                Write-Warning "No batched objects to update. WAPI call cancelled."
                return
            }

            if ($PSCmdlet.ShouldProcess($opts.WAPIHost, 'POST')) {
                Invoke-IBWAPI -Query 'request' -Method 'POST' -Body $body @opts
            }
        }

    }
}
