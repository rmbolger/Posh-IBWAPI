function New-IBObject
{
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory=$True)]
        [Alias('type')]
        [string]$ObjectType,
        [Parameter(Mandatory=$True,ValueFromPipeline=$True)]
        [PSObject]$IBObject,
        [Alias('fields','ReturnFields')]
        [string[]]$ReturnField,
        [Alias('base','ReturnBaseFields')]
        [switch]$ReturnBase,
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
        if ($ReturnField.Count -gt 0) {
            if ($ReturnBase) {
                $querystring = "?_return_fields%2B=$($ReturnField -join ',')"
            }
            else {
                $querystring = "?_return_fields=$($ReturnField -join ',')"
            }
        }
        elseif ($ReturnBase) {
            $querystring = "?_return_fields%2B"
        }

        if ($BatchMode) {
            # create a list to save the objects in
            $deferredObjects = [Collections.Generic.List[PSObject]]::new()
        }
    }

    Process {

        if ($BatchMode) {
            # add the object to the list for processing during End{}
            $deferredObjects.Add($IBObject)
            return
        }

        # process the object now
        $queryParams = @{
            Query = '{0}{1}' -f $ObjectType,$querystring
            Method = 'Post'
            Body = $IBObject
        }
        if ($PSCmdlet.ShouldProcess($queryParams.Uri, "POST")) {
            Invoke-IBWAPI @queryParams @opts
        }
    }

    End {
        if (-not $BatchMode -or $deferredObjects.Count -eq 0) { return }
        Write-Verbose "BatchMode deferred objects: $($deferredObjects.Count), group size $($BatchGroupSize)"

        # build the 'args' value for each object
        $retArgs = @{}
        if ($ReturnField.Count -gt 0) {
            if ($ReturnBase) {
                $retArgs.'_return_fields+' = $ReturnField -join ','
            } else {
                $retArgs.'_return_fields'  = $ReturnField -join ','
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
                    method = 'POST'
                    object = $ObjectType
                    data = $_
                    args = $retArgs
                }
            }

            if ($PSCmdlet.ShouldProcess($opts.WAPIHost, 'POST')) {
                Invoke-IBWAPI -Query 'request' -Method 'POST' -Body $body @opts
            }
        }

    }
}
