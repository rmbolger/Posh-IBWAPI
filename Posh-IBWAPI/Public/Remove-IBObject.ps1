function Remove-IBObject
{
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory=$True,ValueFromPipeline=$True,ValueFromPipelineByPropertyName=$True)]
        [Alias('_ref','ref')]
        [string]$ObjectRef,
        [Alias('args')]
        [string[]]$DeleteArgs,
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
            Invoke-IBWAPI -Query $query -Method Delete @opts
        }
    }

    End {
        if (-not $BatchMode -or $deferredObjects.Count -eq 0) { return }
        Write-Verbose "BatchMode deferred objects: $($deferredObjects.Count)"

        # build the json for all the objects
        $body = $deferredObjects | ForEach-Object {
            @{
                method = 'DELETE'
                object = $_
            }
        }

        if ($PSCmdlet.ShouldProcess($opts.WAPIHost, 'POST')) {
            Invoke-IBWAPI -Query 'request' -Method 'POST' -Body $body @opts
        }

    }
}
