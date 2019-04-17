function Invoke-IBFunction
{
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory=$True,ValueFromPipeline=$True,ValueFromPipelineByPropertyName=$True)]
        [Alias('type')]
        [string]$ObjectType,
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
        [switch]$SkipCertificateCheck
    )

    Begin {

        # grab the variables we'll be using for our REST calls
        $opts = Initialize-CallVars @PSBoundParameters
        $APIBase = $script:APIBaseTemplate -f $opts.WAPIHost,$opts.WAPIVersion
        $opts.Remove('WAPIHost') | Out-Null
        $opts.Remove('WAPIVersion') | Out-Null

    }

    Process {

        $uri = "$APIBase$($ObjectType)?_function=$($FunctionName)"

        if ($FunctionArgs) {
            # convert the function body to json
            $bodyJson = $FunctionArgs | ConvertTo-Json -Compress -Depth 5
            $bodyJson = [Text.Encoding]::UTF8.GetBytes($bodyJson)
            Write-Debug "JSON body:`n$($FunctionArgs | ConvertTo-Json -Depth 5)"

            # make the call
            if ($PSCmdlet.ShouldProcess($uri, "POST")) {
                Invoke-IBWAPI -Method Post -Uri $uri -Body $bodyJson @opts
            }
        }
        else {
            # make the call
            if ($PSCmdlet.ShouldProcess($uri, "POST")) {
                Invoke-IBWAPI -Method Post -Uri $uri @opts
            }
        }

    }





    <#
    .SYNOPSIS
        Call a WAPI function

    .DESCRIPTION
        This function allows you to call a WAPI function given a specific object reference and the function details.

    .PARAMETER ObjectType
        Object type string. (e.g. network, record:host, range)

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
        $mynetwork = @{network='10.10.12.0/24';comment='my network'}
        PS C:\>New-IBObject -ObjectType 'network' -IBObject $mynetwork

        Create a basic new network with a comment.

    .LINK
        Project: https://github.com/rmbolger/Posh-IBWAPI

    .LINK
        Get-IBObject

    #>
}
