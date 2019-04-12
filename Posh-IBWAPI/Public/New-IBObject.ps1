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
        $bodyJson = $IBObject | ConvertTo-Json -Compress -Depth 5
        $bodyJson = [Text.Encoding]::UTF8.GetBytes($bodyJson)
        Write-Verbose "JSON body:`n$($IBObject | ConvertTo-Json -Depth 5)"

        $uri = "$APIBase$($ObjectType)$($querystring)"

        if ($PSCmdlet.ShouldProcess($uri, "POST")) {
            Invoke-IBWAPI -Method Post -Uri $uri -Body $bodyJson @opts
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
        The fully qualified DNS name or IP address of the Infoblox WAPI endpoint (usually the grid master). This parameter is required if not already set using Set-IBConfig.

    .PARAMETER WAPIVersion
        The version of the Infoblox WAPI to make calls against (e.g. '2.2').

    .PARAMETER Credential
        Username and password for the Infoblox appliance. This parameter is required unless it was already set using Set-IBConfig.

    .PARAMETER SkipCertificateCheck
        If set, SSL/TLS certificate validation will be disabled. Overrides value stored with Set-IBConfig.

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
