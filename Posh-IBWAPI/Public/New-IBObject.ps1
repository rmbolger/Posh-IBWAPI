function New-IBObject
{
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory=$True)]
        [Alias('type')]
        [string]$ObjectType,
        [Parameter(Mandatory=$True,ValueFromPipeline=$True)]
        [PSObject[]]$IBObject,
        [Alias('fields')]
        [string[]]$ReturnFields,
        [Alias('base')]
        [switch]$ReturnBaseFields,
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

    }

    Process {
        $bodyJson = $IBObject | ConvertTo-Json -Compress
        Write-Verbose "JSON body:`n$($IBObject | ConvertTo-Json)"

        $uri = "$($cfg.APIBase)$($ObjectType)$($querystring)"

        if ($PSCmdlet.ShouldProcess($uri, "POST")) {
            Invoke-IBWAPI -Method Post -Uri $uri -Body $bodyJson -WebSession $cfg.WebSession -IgnoreCertificateValidation:($cfg.IgnoreCertificateValidation)
        }
    }





    <#
    .SYNOPSIS
        Create an object in Infoblox.

    .DESCRIPTION
        Create an object by specifying the type and a PSObject with the required (and optional) fields for that type.

    .PARAMETER ObjectType
        Object type string. (e.g. network, record:host, range)

    .PARAMETER IBObject
        A PSObject with the required fields for the specified type. Optional fields may also be included.

    .PARAMETER ReturnFields
        The set of fields that should be returned in addition to the object reference.

    .PARAMETER ReturnBaseFields
        If specified, the standard fields for this object type will be returned in addition to the object reference and any additional fields specified by -ReturnFields.

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

    .OUTPUTS
        The object reference string of the created item or a custom object if -ReturnFields or -ReturnBaseFields was used.

    .EXAMPLE
        $mynetwork = @{network='10.10.12.0/24';comment='my network'}
        PS C:\>New-IBObject -ObjectType 'network' -IBObject $mynetwork

        Create a basic new network with a comment.

    .EXAMPLE
        $myhost = @{name='myhost';comment='my host';configure_for_dns=$false}
        PS C:\>$myhost.ipv4addrs = @(@{ipv4addr='func:nextavailableip:10.10.12.0/24'})
        PS C:\>New-IBObject 'record:host' $myhost -ReturnFields 'comment','configure_for_dns' -ReturnBaseFields

        Create a new host record using an embedded function to get the next available IP in the specified network. Returns the basic host fields plus the comment and configure_for_dns fields.

    .EXAMPLE
        $template = @{name='dummy';configure_for_dns=$false;ipv4addrs=@(@{ipv4addr="func:nextavailableip:10.10.12.0/24"})}
        PS C:\>1..5 | %{ $template.name = "myhost$_"; $template } | New-IBObject -ObjectType 'record:host'

        Create a template object. Then create 5 new host records with sequential names using the next 5 available IPs in the specified network based on the template.

    .LINK
        Project: https://github.com/rmbolger/Posh-IBWAPI

    .LINK
        Get-IBObject

    #>
}