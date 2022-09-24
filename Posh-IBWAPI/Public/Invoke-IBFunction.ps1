function Invoke-IBFunction
{
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory=$True,ValueFromPipeline=$True,ValueFromPipelineByPropertyName=$True)]
        [Alias('_ref','ref')]
        [string]$ObjectRef,
        [Parameter(Mandatory=$True)]
        [Alias('name')]
        [string]$FunctionName,
        [Alias('args')]
        [PSObject]$FunctionArgs,
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

    }

    Process {

        $queryParams = @{
            Method = 'Post'
            Uri = '{0}{1}?_function={2}' -f $APIBase,$ObjectRef,$FunctionName
        }
        if ($FunctionArgs) {
            $queryParams.Body = $FunctionArgs
        }

        # make the call
        if ($PSCmdlet.ShouldProcess($queryParams.Uri, "POST")) {
            Invoke-IBWAPI @queryParams @opts
        }

    }





    <#
    .SYNOPSIS
        Call a WAPI function

    .DESCRIPTION
        This function allows you to call a WAPI function given a specific object reference and the function details.

    .PARAMETER ObjectRef
        Object reference string. This is usually found in the "_ref" field of returned objects.

    .PARAMETER FunctionName
        The name of the function to call.

    .PARAMETER FunctionArgs
        An object with the required parameters for the function.

    .PARAMETER WAPIHost
        The fully qualified DNS name or IP address of the Infoblox WAPI endpoint (usually the grid master). This parameter is required if not already set using Set-IBConfig.

    .PARAMETER WAPIVersion
        The version of the Infoblox WAPI to make calls against (e.g. '2.2').

    .PARAMETER Credential
        Username and password for the Infoblox appliance. This parameter is required unless it was already set using Set-IBConfig.

    .PARAMETER SkipCertificateCheck
        If set, SSL/TLS certificate validation will be disabled. Overrides value stored with Set-IBConfig.

    .EXAMPLE
        $grid = Get-IBObject -type grid
        PS C:\>$restartArgs = @{restart_option='RESTART_IF_NEEDED'}
        PS C:\>$grid | Invoke-IBFunction -name restartservices -args $restartArgs

        Restart grid services if necessary.

    .LINK
        Project: https://github.com/rmbolger/Posh-IBWAPI

    .LINK
        Get-IBObject

    #>
}
