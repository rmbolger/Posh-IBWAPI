function Invoke-IBFunction
{
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory=$True,ValueFromPipeline=$True,ValueFromPipelineByPropertyName=$True)]
        [Alias('_ref','ref')]
        [string[]]$ObjectRef,
        [Parameter(Mandatory=$True)]
        [Alias('name')]
        [string]$FunctionName,
        [Alias('args')]
        [PSObject]$FunctionArgs,
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
        $directParams = @{WAPIHost=$WAPIHost;WAPIVersion=$WAPIVersion;Credential=$Credential;WebSession=$WebSession}
        if ($PSBoundParameters.ContainsKey('IgnoreCertificateValidation')) { $directParams.IgnoreCertificateValidation = $IgnoreCertificateValidation }
        $cfg = Initialize-CallVars @directParams

    }

    Process {

        $uri = "$($cfg.APIBase)$($ObjectRef)?_function=$($FunctionName)"

        if ($FunctionArgs) {
            # convert the function body to json
            $bodyJson = $FunctionArgs | ConvertTo-Json -Compress -Depth 5
            Write-Verbose "JSON body:`n$($FunctionArgs | ConvertTo-Json -Depth 5)"

            # make the call
            if ($PSCmdlet.ShouldProcess($uri, "POST")) {
                Invoke-IBWAPI -Method Post -Uri $uri -Body $bodyJson -WebSession $cfg.WebSession -IgnoreCertificateValidation:($cfg.IgnoreCertificateValidation)
            }
        }
        else {
            # make the call
            if ($PSCmdlet.ShouldProcess($uri, "POST")) {
                Invoke-IBWAPI -Method Post -Uri $uri -WebSession $cfg.WebSession -IgnoreCertificateValidation:($cfg.IgnoreCertificateValidation)
            }
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
        The fully qualified DNS name or IP address of the Infoblox WAPI endpoint (usually the grid master). This parameter is required if not already set using Set-IBWAPIConfig.

    .PARAMETER WAPIVersion
        The version of the Infoblox WAPI to make calls against (e.g. '2.2').

    .PARAMETER Credential
        Username and password for the Infoblox appliance. This parameter is required unless -WebSession is specified or was already set using Set-IBWAPIConfig.

    .PARAMETER WebSession
        A WebRequestSession object returned by Get-IBSession or set when using Invoke-IBWAPI with the -SessionVariable parameter. This parameter is required unless -Credential is specified or was already set using Set-IBWAPIConfig.

    .PARAMETER IgnoreCertificateValidation
        If set, SSL/TLS certificate validation will be disabled. Overrides value stored with Set-IBWAPIConfig.

    .EXAMPLE
        $mynetwork = @{network='10.10.12.0/24';comment='my network'}
        PS C:\>New-IBObject -ObjectType 'network' -IBObject $mynetwork

        Create a basic new network with a comment.

    .LINK
        Project: https://github.com/rmbolger/Posh-IBWAPI

    .LINK
        Get-IBObject

    #>
}