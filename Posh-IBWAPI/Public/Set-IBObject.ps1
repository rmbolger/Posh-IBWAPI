function Set-IBObject
{
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(ParameterSetName='ObjectOnly',Mandatory=$True,ValueFromPipeline=$True)]
        [PSObject]$IBObject,

        [Parameter(ParameterSetName='RefAndTemplate',Mandatory=$True,ValueFromPipeline=$True,ValueFromPipelineByPropertyName=$True)]
        [Alias('_ref','ref')]
        [string]$ObjectRef,

        [Parameter(ParameterSetName='RefAndTemplate',Mandatory=$True)]
        [PSObject]$TemplateObject,

        [Alias('fields')]
        [string[]]$ReturnFields,
        [Alias('base')]
        [switch]$ReturnBaseFields,
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

        if ($BatchMode) {
            # create a list to save the objects in
            $deferredObjects = [Collections.Generic.List[PSObject]]::new()
        }
    }

    Process {

        if ($BatchMode) {
            # add the appropriate object to the list for processing during End{}
            if ('ObjectOnly' -eq $PsCmdlet.ParameterSetName) {
                $deferredObjects.Add($IBObject)
            } else {
                $deferredObjects.Add($ObjectRef)
            }
            return
        }

        if ('ObjectOnly' -eq $PsCmdlet.ParameterSetName) {

            # get the ObjectRef from the input object
            if (-not $IBObject._ref) {
                $PSCmdlet.WriteError([Management.Automation.ErrorRecord]::new(
                    "IBObject is missing '_ref' field.", $null, [Management.Automation.ErrorCategory]::InvalidData, $null
                ))
                return
            }
            $ObjectRef = $IBObject._ref
            $IBObject.PSObject.Properties.Remove('_ref')

            $TemplateObject = $IBObject
        }

        # create the json body
        $bodyJson = $TemplateObject | ConvertTo-Json -Compress -Depth 5
        $bodyJson = [Text.Encoding]::UTF8.GetBytes($bodyJson)
        Write-Verbose "JSON body:`n$($TemplateObject | ConvertTo-Json -Depth 5)"

        $uri = '{0}{1}{2}' -f $APIBase,$ObjectRef,$querystring
        if ($PsCmdlet.ShouldProcess($uri, 'PUT')) {
            Invoke-IBWAPI -Method Put -Uri $uri -Body $bodyJson @opts
        }
    }

    End {
        if (-not $BatchMode -or $deferredObjects.Count -eq 0) { return }
        Write-Verbose "BatchMode deferred objects: $($deferredObjects.Count)"

        # build the 'args' value for each object
        $retArgs = @{}
        if ($ReturnFields.Count -gt 0) {
            if ($ReturnBaseFields) {
                $retArgs.'_return_fields+' = $ReturnFields -join ','
            } else {
                $retArgs.'_return_fields'  = $ReturnFields -join ','
            }
        } else {
            $retArgs.'_return_fields+' = ''
        }

        # build the json for all the objects
        $bodyJson = $deferredObjects | ForEach-Object {

            if ('ObjectOnly' -eq $PsCmdlet.ParameterSetName) {

                # get the ObjectRef from the input object
                if (-not $_._ref) {
                    $PSCmdlet.WriteError([Management.Automation.ErrorRecord]::new(
                        "IBObject is missing '_ref' field.", $null, [Management.Automation.ErrorCategory]::InvalidData, $null
                    ))
                    return
                }
                $ObjectRef = $_._ref
                $_.PSObject.Properties.Remove('_ref')

                $TemplateObject = $_
            } else {
                $ObjectRef = $_
            }

            @{
                method = 'PUT'
                object = $ObjectRef
                data = $TemplateObject
                args = $retArgs
            }
        } | ConvertTo-Json -Compress -Depth 5

        if ([String]::IsNullOrWhiteSpace($bodyJson)) {
            Write-Warning "No batched objects to update. WAPI call cancelled."
            return
        }
        $bodyJson = [Text.Encoding]::UTF8.GetBytes($bodyJson)

        $uri = '{0}request' -f $APIBase
        if ($PSCmdlet.ShouldProcess($uri, 'POST')) {
            Invoke-IBWAPI -Method Post -Uri $uri -Body $bodyJson @opts
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

    .PARAMETER BatchMode
        If specified, objects passed via pipeline will be batched together into groups and sent as a single WAPI call per group instead of a WAPI call per object. This can increase performance but if any of the individual calls fail, the whole group is cancelled.

    .PARAMETER WAPIHost
        The fully qualified DNS name or IP address of the Infoblox WAPI endpoint (usually the grid master). This parameter is required if not already set using Set-IBConfig.

    .PARAMETER WAPIVersion
        The version of the Infoblox WAPI to make calls against (e.g. '2.2').

    .PARAMETER Credential
        Username and password for the Infoblox appliance. This parameter is required unless it was already set using Set-IBConfig.

    .PARAMETER SkipCertificateCheck
        If set, SSL/TLS certificate validation will be disabled. Overrides value stored with Set-IBConfig.

    .OUTPUTS
        The object reference string of the modified item or a custom object if -ReturnFields or -ReturnBaseFields was used.

    .EXAMPLE
        $myhost = Get-IBObject -ObjectType 'record:host' -Filter 'name=myhost' -ReturnFields 'comment'
        PS C:\>$myhost.comment = 'new comment'
        PS C:\>Set-IBObject -ObjectRef $myhost._ref -IBObject $myhost

        Search for a host record called 'myhost', update the comment field, and save it.

    .EXAMPLE
        $toChange = Get-IBObject -type 'record:host' -Filter 'name~=oldname' -fields 'name'
        PS C:\>$toChange | %{ $_.name = $_.name.Replace('oldname','newname'); $_ } | Set-IBObject

        Find all hosts with 'oldname' in the name, change the references to 'newname', and send them through the pipeline to Set-IBObject for saving.

    .EXAMPLE
        $myhosts = Get-IBObject 'record:host' -Filter 'comment=web server'
        PS C:\>$myhosts | Set-IBObject -TemplateObject @{comment='db server'}

        Find all host records with comment 'web server' and change them to 'db server' with a manually created template

    .LINK
        Project: https://github.com/rmbolger/Posh-IBWAPI

    .LINK
        Get-IBObject

    #>
}
