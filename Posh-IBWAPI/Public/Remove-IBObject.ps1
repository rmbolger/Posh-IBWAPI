function Remove-IBObject
{
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory=$True,ValueFromPipeline=$True,ValueFromPipelineByPropertyName=$True)]
        [Alias('_ref','ref')]
        [string[]]$ObjectRef,
        [Alias('args')]
        [string[]]$DeleteArgs,
        [Alias('host')]
        [string]$WAPIHost,
        [Alias('version')]
        [string]$WAPIVersion,
        [PSCredential]$Credential,
        [Alias('session')]
        [Microsoft.PowerShell.Commands.WebRequestSession]$WebSession,
        [switch]$IgnoreCertificateValidation
    )

    Begin {
        # grab the variables we'll be using for our REST calls
        $cfg = Initialize-CallVars @PSBoundParameters
        $APIBase = Base @cfg
        $cfg.Remove('WAPIHost') | Out-Null
        $cfg.Remove('WAPIVersion') | Out-Null

        if ($DeleteArgs) {
            $querystring = "?$($DeleteArgs -join '&')"
        }
    }

    Process {
        $uri = "$APIBase$($ObjectRef)$querystring"
        if ($PSCmdlet.ShouldProcess($uri, 'DELETE')) {
            Invoke-IBWAPI -Method Delete -Uri $uri @cfg
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

    .PARAMETER WAPIHost
        The fully qualified DNS name or IP address of the Infoblox WAPI endpoint (usually the grid master). This parameter is required if not already set using Set-IBWAPIConfig.

    .PARAMETER WAPIVersion
        The version of the Infoblox WAPI to make calls against (e.g. '2.2'). You may optionally specify 'latest' and the function will attempt to query the WAPI for the latest supported version. This will only work if WAPIHost and Credential or WebSession are already configured.

    .PARAMETER Credential
        Username and password for the Infoblox appliance. This parameter is required unless -WebSession is specified or was already set using Set-IBWAPIConfig.

    .PARAMETER WebSession
        A WebRequestSession object returned by Get-IBSession or set when using Invoke-IBWAPI with the -SessionVariable parameter. This parameter is required unless -Credential is specified or was already set using Set-IBWAPIConfig.

    .PARAMETER IgnoreCertificateValidation
        If set, SSL/TLS certificate validation will be disabled. Overrides value stored with Set-IBWAPIConfig.

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