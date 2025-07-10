function Remove-IBObject
{
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory,Position=0,ValueFromPipeline,ValueFromPipelineByPropertyName)]
        [Alias('_ref','ref')]
        [string]$ObjectRef,
        [Parameter(Position=1)]
        [Alias('args')]
        [string[]]$DeleteArgs,
        [switch]$BatchMode,
        [ValidateRange(1,2147483647)]
        [int]$BatchGroupSize = 1000,

        [ValidateScript({Test-ValidProfile $_ -ThrowOnFail})]
        [string]$ProfileName,
        [ValidateScript({Test-NonEmptyString $_ -ThrowOnFail})]
        [Alias('host')]
        [string]$WAPIHost,
        [ValidateScript({Test-VersionString $_ -ThrowOnFail})]
        [Alias('version')]
        [string]$WAPIVersion,
        [PSCredential]$Credential,
        [switch]$SkipCertificateCheck,
        [switch]$NoSession
    )

    Begin {
        # grab the variables we'll be using for our REST calls
        try { $opts = Initialize-CallVars @PSBoundParameters } catch { $PsCmdlet.ThrowTerminatingError($_) }

        $querystring = [String]::Empty
        if ($DeleteArgs) {
            $querystring = "?$($DeleteArgs -join '&')"
        }

        if ($BatchMode) {
            # create a list to save the objects in
            $deferredObjects = [Collections.Generic.List[string]]::new()
        }
    }

    Process {

        if ($BatchMode) {
            # add the object to the list for processing during End{}
            $deferredObjects.Add($ObjectRef)
            return
        }

        $query = '{0}{1}' -f $ObjectRef,$querystring
        if ($PSCmdlet.ShouldProcess($opts.WAPIHOST, 'DELETE')) {
            try {
                Invoke-IBWAPI -Query $query -Method Delete @opts -EA Stop
            } catch { $PsCmdlet.WriteError($_) }
        }
    }

    End {
        if (-not $BatchMode -or $deferredObjects.Count -eq 0) { return }
        Write-Verbose "BatchMode deferred objects: $($deferredObjects.Count), group size $($BatchGroupSize)"

        # make calls based on the group size
        for ($i=0; $i -lt $deferredObjects.Count; $i += $BatchGroupSize) {
            $groupEnd = [Math]::Min($deferredObjects.Count, ($i+$BatchGroupSize-1))

            # build the json for this group's objects
            $body = $deferredObjects[$i..$groupEnd] | ForEach-Object {
                @{
                    method = 'DELETE'
                    object = $_
                }
            }

            if ($PSCmdlet.ShouldProcess($opts.WAPIHost, 'POST')) {
                try {
                    Invoke-IBWAPI -Query 'request' -Method 'POST' -Body $body @opts -EA Stop
                } catch { $PsCmdlet.WriteError($_) }
            }
        }

    }
}
