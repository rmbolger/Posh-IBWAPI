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
        $APIBase = $script:APIBaseTemplate -f $opts.WAPIHost,$opts.WAPIVersion
        $opts.Remove('WAPIHost') | Out-Null
        $opts.Remove('WAPIVersion') | Out-Null

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

        $uri = '{0}{1}{2}' -f $APIBase,$ObjectRef,$querystring
        if ($PSCmdlet.ShouldProcess($uri, 'DELETE')) {
            Invoke-IBWAPI -Method Delete -Uri $uri @opts
        }
    }

    End {
        if (-not $BatchMode -or $deferredObjects.Count -eq 0) { return }
        Write-Verbose "BatchMode deferred objects: $($deferredObjects.Count)"

        # build the json for all the objects
        $bodyJson = $deferredObjects | ForEach-Object {
            @{
                method = 'DELETE'
                object = $_
            }
        } | ConvertTo-Json -Compress -Depth 5
        $bodyJson = [Text.Encoding]::UTF8.GetBytes($bodyJson)

        $uri = '{0}request' -f $APIBase
        if ($PSCmdlet.ShouldProcess($uri, 'POST')) {
            Invoke-IBWAPI -Method Post -Uri $uri -Body $bodyJson @opts
        }

    }




    <#
    .SYNOPSIS
        Delete an object from Infoblox.

    .DESCRIPTION
        Specify an object reference to delete that object from the Infoblox database.

    .PARAMETER ObjectRef
        Object reference string. This is usually found in the "_ref" field of returned objects.

    .PARAMETER DeleteArgs
        Additional delete arguments for this object. For example, 'remove_associated_ptr=true' can be used with record:a. Requires WAPI 2.1+.

    .PARAMETER BatchMode
        If specified, objects passed via pipeline will be batched together into groups and sent as a single WAPI call per group instead of a WAPI call per object. This can increase performance but if any of the individual calls fail, the whole group is cancelled.

    .PARAMETER WAPIHost
        The fully qualified DNS name or IP address of the Infoblox WAPI endpoint (usually the grid master). This parameter is required if not already set using Set-IBConfig.

    .PARAMETER WAPIVersion
        The version of the Infoblox WAPI to make calls against (e.g. '2.2'). You may optionally specify 'latest' and the function will attempt to query the WAPI for the latest supported version.

    .PARAMETER Credential
        Username and password for the Infoblox appliance. This parameter is required unless it was already set using Set-IBConfig.

    .PARAMETER SkipCertificateCheck
        If set, SSL/TLS certificate validation will be disabled. Overrides value stored with Set-IBConfig.

    .OUTPUTS
        The object reference string of the deleted item.

    .EXAMPLE
        $myhost = Get-IBObject -ObjectType 'record:host' -Filters 'name=myhost'
        PS C:\>Remove-IBObject -ObjectRef $myhost._ref

        Search for a host record called 'myhost' and delete it.

    .EXAMPLE
        $hostsToDelete = Get-IBObject 'record:host' -Filters 'comment=decommissioned'
        PS C:\>$hostsToDelete | Remove-IBObject

        Search for hosts with their comment set to 'decommissioned' and delete them all.

    .LINK
        Project: https://github.com/rmbolger/Posh-IBWAPI

    .LINK
        New-IBObject

    .LINK
        Get-IBObject

    #>
}
