function New-IBObject
{
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory=$True)]
        [Alias('type')]
        [string]$ObjectType,
        [Parameter(Mandatory=$True,ValueFromPipeline=$True)]
        [PSObject]$IBObject,
        [Alias('fields')]
        [string[]]$ReturnFields,
        [Alias('base')]
        [switch]$ReturnBaseFields,
        [switch]$BatchMode,
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
