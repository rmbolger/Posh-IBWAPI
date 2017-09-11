function Get-IBSchema {
    [CmdletBinding()]
    param(
        [Alias('type')]
        [string]$ObjectType,
        [switch]$Raw,
        [string[]]$Fields,
        [string[]]$Operations,
        [switch]$NoFields,
        [string[]]$Functions,
        [switch]$NoFunctions,
        [switch]$Detailed,
        [Alias('host')]
        [string]$WAPIHost,
        [Alias('version')]
        [string]$WAPIVersion,
        [PSCredential]$Credential,
        [Alias('session')]
        [Microsoft.PowerShell.Commands.WebRequestSession]$WebSession,
        [switch]$IgnoreCertificateValidation
    )

    # grab the variables we'll be using for our REST calls
    $opts = Initialize-CallVars @PSBoundParameters
    $APIBase = Base @opts
    $WAPIHost = $opts.WAPIHost
    $WAPIVersion = $opts.WAPIVersion
    $opts.Remove('WAPIHost') | Out-Null
    $opts.Remove('WAPIVersion') | Out-Null

    # make sure there's a config set reference for this host
    # and get a reference to it
    Set-IBWAPIConfig -WAPIHost $WAPIHost -NoSwitchProfile
    $cfg = $script:Config.$WAPIHost

    # make sure we can actually query schema stuff for this WAPIHost
    if (!$cfg.HighestVersion) {
        if (!$opts.WebSession) {
            $opts.WebSession = New-Object Microsoft.PowerShell.Commands.WebRequestSession
            $opts.WebSession.Credentials = $opts.Credential.GetNetworkCredential()
        }
        $cfg.HighestVersion = (HighestVer $WAPIHost $opts.WebSession -IgnoreCertificateValidation:$opts.IgnoreCertificateValidation)
        Write-Verbose "Set highest version: $($cfg.HighestVersion)"
    }
    if ([Version]$cfg.HighestVersion -lt [Version]'1.7.5') {
        throw "NIOS WAPI $($cfg.HighestVersion) doesn't support schema queries"
    }

    # cache some base schema stuff that we'll potentially need later
    if (!$cfg.SupportedVersions -or !$cfg[$WAPIVersion]) {
        $schema = Invoke-IBWAPI -Uri "$($APIBase)?_schema" @opts

        # set supported versions
        $cfg.SupportedVersions = $schema.supported_versions | Sort-Object @{E={[Version]$_}}
        Write-Verbose "Set supported versions: $($cfg.SupportedVersions -join ', ')"

        # set supported objects for this version
        $cfg[$WAPIVersion] = $schema.supported_objects | Sort-Object
        Write-Verbose "Set supported objects: $($cfg[$WAPIVersion] -join ', ')"
    }

    # The 'request' object is a weird outlier that only accepts POST requests against it
    # and I haven't been able to figure out how to query its schema using POST. So for
    # now, just warn and exit if we've been asked to query it.
    if ($ObjectType -eq 'request') {
        Write-Warning "The 'request' object is not currently supported for schema queries"
        return
    }

    if (![String]::IsNullOrWhiteSpace($ObjectType)) {
        # We want to support wildcard searches and partial matching on object types.
        Write-Verbose "ObjectType: $ObjectType"
        $objMatches = $cfg[$WAPIVersion] | %{ if ($_ -like $ObjectType) { $_ } }
        Write-Verbose "Matches: $($objMatches.Count)"
        if ($objMatches.count -gt 1) {
            # multiple matches
            $message = "Multiple object matches found for $($ObjectType)"
            if ($Raw) { throw $message }
            "$($message):" | Word-Wrap -Pad | Write-Host
            $objMatches | %{ $_ | Word-Wrap -Pad | Write-Host }
            return
        }
        elseif ($objMatches.count -eq 0 ) {
            Write-Verbose "Retrying matches with implied wildcards"
            # retry matching with implied wildcards
            $objMatches = $cfg[$WAPIVersion] | %{ if ($_ -like "*$ObjectType*") { $_ } }
            if ($objMatches.count -gt 1) {
                # multiple matches
                $message = "Multiple object matches found for $($ObjectType)"
                if ($Raw) { throw $message }
                "$($message):" | Word-Wrap -Pad | Write-Host
                $objMatches | %{ $_ | Word-Wrap -Pad | Write-Host }
                return
            }
            elseif ($objMatches.count -eq 0) {
                # no matches, even with wildcards
                $message = "No matches found for $($ObjectType)"
                if ($Raw) { throw $message }
                else { $message | Word-Wrap -Pad | Write-Warning }
                return
            } else {
                $ObjectType = $objMatches
            }
        }
        else {
            # only one match
            $ObjectType = $objMatches
        }
    }

    # As of WAPI 2.6 (NIOS 8.1), schema queries get a lot more helpful with the addition of
    # _schema_version, _schema_searchable, and _get_doc. The odd thing is that those fields
    # are even available if you query old WAPI versions. But if you're *actually* on an
    # old WAPI version, they generate an error.
    #
    # We want to give people as much information as possible. So instead of conditionally
    # using the additional schema options if the requested WAPI version supports it, we want
    # to always do it as long as the latest *supported* WAPI version supports them.
    $uri = "$APIBase$($ObjectType)?_schema=1"
    if ([Version]$cfg.HighestVersion -ge [Version]'2.6') {
        $uri += "&_schema_version=2&_schema_searchable=1&_get_doc=1"
    }

    $schema = Invoke-IBWAPI -Uri $uri @opts

    # return the schema object directly, if asked
    if ($Raw) { return $schema }

    function BlankLine() { ' ' | Word-Wrap -Pad | Write-Host }
    function PrettifySupports([string]$supports) {
        # The 'supports' property of a schema Field is a lower cases string
        # containing one or more of r,w,u,d,s for the supported operations of
        # that field. Most, but not all, are in a standard order. There are
        # instances of things like 'wu' vs 'uw'. We want to standardize the
        # order (RWUSD), uppercase the letters, and insert spaces for the operations
        # not included in the list.
        $ret = ''
        'R','W','U','D','S' | %{
            if ($supports -like "*$_*") {
                $ret += $_
            } else {
                $ret += ' '
            }
        }
        $ret
        # Basic string concatentation obviously isn't the most efficient thing to
        # do here. But we can optimize later if it becomes a problem.
    }
    function PrettifySupportsDetail([string]$supports) {
        # The 'supports' property of a schema Field is a lower cases string
        # containing one or more of r,w,u,s,d for the supported operations of
        # that field. Most, but not all, are in a standard order. There are
        # instances of things like 'wu' vs 'uw'. We want to spell out the operations
        # for the detailed view.
        $ret = @()
        if ($supports -like '*r*') { $ret += 'Read' }
        if ($supports -like '*w*') { $ret += 'Write' }
        if ($supports -like '*u*') { $ret += 'Update' }
        if ($supports -like '*d*') { $ret += 'Delete' }
        if ($supports -like '*s*') { $ret += 'Search' }
        ($ret -join ', ')
        # Basic string concatentation obviously isn't the most efficient thing to
        # do here. But we can optimize later if it becomes a problem.
    }

    function PrettifyType($field) {

        if ($field.enum_values) {
            $type = "{ $($field.enum_values -join ' | ') }"
            if ($field.is_array) { $type = "$type[]" }
        } else {
            if ($field.is_array) {
                $type = ($field.type | %{ "$_[]" }) -join ' | '
            } else {
                $type = $field.type -join '|'
            }
        }

        $type
    }

    if (!$schema.type) {
        # base schema object
        BlankLine
        "Requested Version: $($schema.requested_version)" | Word-Wrap -Pad | Write-Host
        BlankLine
        "Supported Versions:" | Word-Wrap -Pad | Write-Host
        BlankLine
        $schema | Select-Object -expand supported_versions | Format-Columns -prop {$_} -col 4
        BlankLine
        "Supported Objects:" | Word-Wrap -Pad | Write-Host
        BlankLine
        $schema | Select-Object -expand supported_objects | Format-Columns -prop {$_}
        BlankLine
    }
    else {
        # display the top level object info
        $typeStr = "$($schema.type) (WAPI $($schema.version))"
        BlankLine
        'OBJECT' | Word-Wrap -Pad | Write-Host
        $typeStr | Word-Wrap -Pad -Indent 4 | Write-Host
        if ($schema.restrictions) {
            BlankLine
            'RESTRICTIONS' | Word-Wrap -Pad | Write-Host
            "$($schema.restrictions -join ', ')" | Word-Wrap -Pad -Indent 4 | Write-Host
        }
        if ($schema.cloud_additional_restrictions) {
            BlankLine
            'CLOUD RESTRICTIONS' | Word-Wrap -Pad | Write-Host
            "$($schema.cloud_additional_restrictions -join ', ')" | Word-Wrap -Pad -Indent 4 | Write-Host
        }

        # With _schema_version=2, functions are returned in the normal
        # list of fields. But we want to split those out and display them differently.
        $fieldList = @($schema.fields | ?{ $_.wapi_primitive -ne 'funccall' })
        $funcList  = @($schema.fields | ?{ $_.wapi_primitive -eq 'funccall' })

        # filter the fields if specified
        if ($Fields.count -gt 0) {
            $fieldList = @($fieldList | ?{
                $name = $_.name
                ($Fields | %{ $name -like $_ }) -contains $true
            })
        }
        # filter fields that don't include at least one specified Operation unless no operations were specified
        if ($Operations.count -gt 0) {
            $fieldList = @($fieldList | ?{
                $supports = $_.supports
                ($Operations | %{ $supports -like "*$_*"}) -contains $true
            })
        }
        # filter the functions if specified
        if ($Functions.count -gt 0) {
            $funcList = @($funcList | ?{
                $name = $_.name
                ($Functions | %{ $name -like $_ }) -contains $true
            })
        }

        if ($fieldList.count -gt 0 -and !$NoFields) {

            if ($Detailed) {
                # Display the detailed view

                BlankLine
                'FIELDS' | Word-Wrap -Pad | Write-Host

                # loop through fields alphabetically
                $fieldList | sort name | %{

                    "$($_.name) <$(PrettifyType $_)>" | Word-Wrap -Indent 4 -Pad | Write-Host

                    if ($_.doc) {
                        $_.doc | Word-Wrap -Indent 8 -Pad | Write-Host
                        BlankLine
                    }

                    "Supports: $(PrettifySupportsDetail $_.supports)" | Word-Wrap -Indent 8 -Pad | Write-Host

                    if ($_.overridden_by) {
                        "Overridden By: $($_.overridden_by)" | Word-Wrap -Indent 8 -Pad | Write-Host
                    }
                    if ($_.standard_field) {
                        "This field is part of the base object." | Word-Wrap -Indent 8 -Pad | Write-Host
                    }
                    if ($_.searchable_by) {
                        BlankLine
                        "This field is available for search via:" | Word-Wrap -Indent 8 -Pad | Write-Host
                        if ($_.searchable_by -like '*=*') { "'=' (exact equality)" | Word-Wrap -Indent 12 -Pad | Write-Host }
                        if ($_.searchable_by -like '*!*') { "'!=' (negative equality)" | Word-Wrap -Indent 12 -Pad | Write-Host }
                        if ($_.searchable_by -like '*:*') { "':=' (case insensitive search)" | Word-Wrap -Indent 12 -Pad | Write-Host }
                        if ($_.searchable_by -like '*~*') { "'~=' (regular expression)" | Word-Wrap -Indent 12 -Pad | Write-Host }
                        if ($_.searchable_by -like '*<*') { "'<=' (less than or equal to)" | Word-Wrap -Indent 12 -Pad | Write-Host }
                        if ($_.searchable_by -like '*>*') { "'>=' (greater than or equal to)" | Word-Wrap -Indent 12 -Pad | Write-Host }
                    }

                    # supports_inline_funccall
                    # schema? (sub object defs)
                    # wapi_primitive = struct?

                    BlankLine

                }

            } else {
                # Display the simple view

                # get the length of the longest field name so we can make sure not to truncate that column
                $nameMax = [Math]::Max(($fieldList.name | sort -desc @{E={$_.length}} | select -first 1).length + 1, 6)
                # get the length of the longest type name (including potential array brackets) so we can
                # make sure not to truncate that column
                $typeMax = [Math]::Max(($fieldList.type | sort -desc @{E={$_.length}} | select -first 1).length + 3, 5)

                $format = "{0,-$nameMax}{1,-$typeMax}{2,-9}{3,-5}{4,-6}"
                BlankLine
                ($format -f 'FIELD','TYPE','SUPPORTS','BASE','SEARCH') | Word-Wrap -Pad | Write-Host
                ($format -f '-----','----','--------','----','------') | Word-Wrap -Pad | Write-Host

                # loop through fields alphabetically
                $fieldList | sort @{E='name';Desc=$false} | %{

                    # set the Base column value
                    $base = ''
                    if ($_.standard_field) { $base = 'X' }

                    # put brackets on array types
                    if ($_.is_array) {
                        for ($i=0; $i -lt $_.type.count; $i++) {
                            $_.type[$i] = "$($_.type[$i])[]"
                        }
                    }

                    # there should always be at least one type, so write that with the rest of
                    # the table values
                    ($format -f $_.name,$_.type[0],(PrettifySupports $_.supports),$base,$_.searchable_by) | Word-Wrap -Pad | Write-Host

                    # write additional types on their own line
                    if ($_.type.count -gt 1) {
                        for ($i=1; $i -lt $_.type.count; $i++) {
                            "$(''.PadRight($nameMax))$($_.type[$i])" | Word-Wrap -Pad | Write-Host
                        }
                    }
                }
            } # end simple field view
        } # end fields

        if ($funcList.count -gt 0 -and !$NoFunctions) {

            BlankLine
            "FUNCTIONS" | Word-Wrap -Pad | Write-Host

            if ($Detailed) {

                $funcList | %{
                    BlankLine
                    '    ----------------------------------------------------------' | Word-Wrap -Pad | Write-Host
                    $_.name | Word-Wrap -Indent 4 -Pad | Write-Host
                    '    ----------------------------------------------------------' | Word-Wrap -Pad | Write-Host
                    if ($_.doc) {
                        $_.doc | Word-Wrap -Indent 8 -Pad | Write-Host
                    }
                    if ($_.schema.input_fields.count -gt 0) {
                        BlankLine
                        "INPUTS" | Word-Wrap -Indent 4 -Pad | Write-Host
                        foreach ($field in $_.schema.input_fields) {
                            BlankLine
                            "$($field.name) <$(PrettifyType $field)>" | Word-Wrap -Indent 8 -Pad | Write-Host
                            $field.doc | Word-Wrap -Indent 12 -Pad | Write-Host
                        }
                    }
                    if ($_.schema.output_fields.count -gt 0) {
                        BlankLine
                        "OUTPUTS" | Word-Wrap -Indent 4 -Pad | Write-Host
                        foreach ($field in $_.schema.output_fields) {
                            BlankLine
                            "$($field.name) <$(PrettifyType $field)>" | Word-Wrap -Indent 8 -Pad | Write-Host
                            $field.doc | Word-Wrap -Indent 12 -Pad | Write-Host
                        }
                    }

                }

            } else {

                $funcList | %{
                    $funcListtr = "$($_.name)($($_.schema.input_fields.name -join ', '))"
                    if ($_.schema.output_fields.count -gt 0) {
                        $funcListtr += " => $($_.schema.output_fields.name -join ', ')"
                    }
                    $funcListtr | Word-Wrap -Indent 4 -Pad | Write-Host
                }

            } # end simple function view
        } # end functions

        BlankLine
    }




    <#
    .SYNOPSIS
        Query the schema of an object or the base appliance.

    .DESCRIPTION
        Without any parameters, this function will return the base appliance schema object which includes the list of supported WAPI versions and object types. Providing an -ObjectType will return the schema object for that type which includes a list of supported fields and functions.

    .PARAMETER ObjectType
        Object type string. (e.g. network, record:host, range). Partial names and wildcards are supported. If the ObjectType parameter would match multiple objects, the list of matching objects will be returned.

    .PARAMETER Raw
        If set, the schema object will be returned as-is rather than pretty printing the output. All parameters except -ObjectType will be ignored.

    .PARAMETER Fields
        A list of Field names to include in the output. Wildcards are supported. This parameter is ignored if -NoFields is specified. If neither is specified, all Fields will be included.

    .PARAMETER Operations
        A list of supported operation codes: r (read), w (write/create), u (update/set), s (search), d (delete). Only the Fields supporting at least one of these operations will be included in the output. If not specified, all Fields will be included.

    .PARAMETER NoFields
        If set, the object's fields will not be included in the output.

    .PARAMETER Functions
        A list of Function names to include in the output. Wildcards are supported. This parameter is ignored if -NoFunctions is specified. If neither is specified, all Functions will be included.

    .PARAMETER NoFunctions
        If set, the object's functions will not be included in the output.

    .PARAMETER Detailed
        If set, detailed output is displayed for field and function information. Otherwise, a simplified view is displayed.

    .PARAMETER WAPIHost
        The fully qualified DNS name or IP address of the Infoblox WAPI endpoint (usually the grid master). This parameter is required if not already set using Set-IBWAPIConfig.

    .PARAMETER WAPIVersion
        The version of the Infoblox WAPI to make calls against (e.g. '2.2'). This parameter is required if not already set using Set-IBWAPIConfig.

    .PARAMETER Credential
        Username and password for the Infoblox appliance. This parameter is required unless -WebSession is specified or was already set using Set-IBWAPIConfig.

    .PARAMETER WebSession
        A WebRequestSession object returned by Get-IBSession or set when using Invoke-IBWAPI with the -SessionVariable parameter. This parameter is required unless -Credential is specified or was already set using Set-IBWAPIConfig.

    .PARAMETER IgnoreCertificateValidation
        If set, SSL/TLS certificate validation will be disabled. Overrides value stored with Set-IBWAPIConfig.

    .OUTPUTS
        Zero or more objects found by the search or object reference. If an object reference is specified that doesn't exist, an error will be thrown.

    .EXAMPLE
        Get-IBSchema

        Get the root schema object.

    .EXAMPLE
        Get-IBSchema record:host

        Get the record:host schema object.

    .EXAMPLE
        Get-IBSchema record:host -Raw

        Get the record:host schema object in raw object form.

    .EXAMPLE
        Get-IBSchema grid -Fields enable*,name

        Get the grid schema object and only include the name field and fields that start with 'enable'.

    .EXAMPLE
        Get-IBSchema network -Operations s -NoFunctions

        Get the network schema object and only include fields that are searchable and skip function definitions.

    .LINK
        Project: https://github.com/rmbolger/Posh-IBWAPI

    .LINK
        Get-IBObject

    #>
}