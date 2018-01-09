function Set-IBObject
{
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(ParameterSetName='ObjectOnly',Mandatory=$True,ValueFromPipeline=$True)]
        [PSObject[]]$IBObject,

        [Parameter(ParameterSetName='RefAndTemplate',Mandatory=$True,ValueFromPipeline=$True,ValueFromPipelineByPropertyName=$True)]
        [Alias('_ref','ref')]
        [string[]]$ObjectRef,

        [Parameter(ParameterSetName='RefAndTemplate',Mandatory=$True)]
        [PSObject]$TemplateObject,

        [Parameter(ParameterSetName='ObjectOnly')]
        [Parameter(ParameterSetName='RefAndTemplate')]
        [Alias('fields')]
        [string[]]$ReturnFields,
        [Parameter(ParameterSetName='ObjectOnly')]
        [Parameter(ParameterSetName='RefAndTemplate')]
        [Alias('base')]
        [switch]$ReturnBaseFields,
        [Parameter(ParameterSetName='ObjectOnly')]
        [Parameter(ParameterSetName='RefAndTemplate')]
        [Alias('host')]
        [string]$WAPIHost,
        [Parameter(ParameterSetName='ObjectOnly')]
        [Parameter(ParameterSetName='RefAndTemplate')]
        [Alias('version')]
        [string]$WAPIVersion,
        [Parameter(ParameterSetName='ObjectOnly')]
        [Parameter(ParameterSetName='RefAndTemplate')]
        [PSCredential]$Credential,
        [Parameter(ParameterSetName='ObjectOnly')]
        [Parameter(ParameterSetName='RefAndTemplate')]
        [Alias('session')]
        [Microsoft.PowerShell.Commands.WebRequestSession]$WebSession,
        [Parameter(ParameterSetName='ObjectOnly')]
        [Parameter(ParameterSetName='RefAndTemplate')]
        [switch]$IgnoreCertificateValidation
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

        switch ($PsCmdlet.ParameterSetName) {
            "ObjectOnly" {
                if (!$IBObject._ref) {
                    throw "IBObject is missing '_ref' field."
                }
                # copy out the ObjectRef from the object
                $ObjectRef = $IBObject._ref

                # create the json body
                $bodyJson = $IBObject | ConvertTo-Json -Compress -Depth 5
                $bodyJson = [Text.Encoding]::UTF8.GetBytes($bodyJson)
                Write-Verbose "JSON body:`n$($IBObject | ConvertTo-Json -Depth 5)"
            }
            "RefAndTemplate" {
                # create the json body
                $bodyJson = $TemplateObject | ConvertTo-Json -Compress -Depth 5
                $bodyJson = [Text.Encoding]::UTF8.GetBytes($bodyJson)
                Write-Verbose "JSON body:`n$($TemplateObject | ConvertTo-Json -Depth 5)"
            }
        }
        $uri = "$APIBase$($ObjectRef)$($querystring)"
        if ($PsCmdlet.ShouldProcess($uri, 'PUT')) {
            Invoke-IBWAPI -Method Put -Uri $uri -Body $bodyJson @opts
        }

    }




    <#
    .SYNOPSIS
        Modify an object in Infoblox.

    .DESCRIPTION
        Modify an object by specifying its object reference and a PSObject with the fields to change.

    .PARAMETER IBObject
        An object with the fields to be modified. This must include a '_ref' with the object reference string to modify. All included fields will be modified even if they are empty.

    .PARAMETER ObjectRef
        Object reference string. This is usually found in the "_ref" field of returned objects.

    .PARAMETER TemplateObject
        An object with the fields to be modified. A '_ref' field in this object will be ignored. This is only usable with a separate -ObjectRef parameter.

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
        The object reference string of the modified item or a custom object if -ReturnFields or -ReturnBaseFields was used.

    .EXAMPLE
        $myhost = Get-IBObject -ObjectType 'record:host' -Filters 'name=myhost' -ReturnFields 'comment'
        PS C:\>$myhost.comment = 'new comment'
        PS C:\>Set-IBObject -ObjectRef $myhost._ref -IBObject $myhost

        Search for a host record called 'myhost', update the comment field, and save it.

    .EXAMPLE
        $toChange = Get-IBObject -type 'record:host' -Filters 'name~=oldname' -fields 'name'
        PS C:\>$toChange | %{ $_.name = $_.name.Replace('oldname','newname'); $_ } | Set-IBObject

        Find all hosts with 'oldname' in the name, change the references to 'newname', and send them through the pipeline to Set-IBObject for saving.

    .EXAMPLE
        $myhosts = Get-IBObject 'record:host' -Filters 'comment=web server'
        PS C:\>$myhosts | Set-IBObject -TemplateObject @{comment='db server'}

        Find all host records with comment 'web server' and change them to 'db server' with a manually created template

    .LINK
        Project: https://github.com/rmbolger/Posh-IBWAPI

    .LINK
        Get-IBObject

    #>
}