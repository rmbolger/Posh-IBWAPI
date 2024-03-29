function Get-IBSchema {
    [CmdletBinding()]
    param(
        [Alias('type')]
        [string]$ObjectType,
        [switch]$Raw,
        [switch]$LaunchHTML,
        [string[]]$Fields,
        [string[]]$Operations,
        [switch]$NoFields,
        [string[]]$Functions,
        [switch]$NoFunctions,
        [switch]$Detailed,

        [ValidateScript({Test-ValidProfile $_ -ThrowOnFail})]
        [string]$ProfileName,
        [ValidateScript({Test-NonEmptyString $_ -ThrowOnFail})]
        [Alias('host')]
        [string]$WAPIHost,
        [ValidateScript({Test-VersionString $_ -ThrowOnFail})]
        [Alias('version')]
        [string]$WAPIVersion,
        [PSCredential]$Credential,
        [switch]$SkipCertificateCheck
    )

    # grab the variables we'll be using for our REST calls
    try { $opts = Initialize-CallVars @PSBoundParameters } catch { $PsCmdlet.ThrowTerminatingError($_) }
    $WAPIHost = $opts.WAPIHost
    $WAPIVersion = $opts.WAPIVersion

    # add a schema cache for this host if it doesn't exist
    if (-not $script:Schemas.$WAPIHost) {
        $script:Schemas.$WAPIHost = @{ ReadFields = @{} }
    }
    $sCache = $script:Schemas.$WAPIHost

    # make sure we can actually query schema stuff for this WAPIHost
    if (-not $sCache.HighestVersion) {
        try {
            $sCache.HighestVersion = (HighestVer @opts)
        } catch { $PSCmdlet.ThrowTerminatingError($_) }
        Write-Debug "Set highest version: $($sCache.HighestVersion)"
    }
    if ([Version]$sCache.HighestVersion -lt [Version]'1.7.5') {
        $PSCmdlet.ThrowTerminatingError([Management.Automation.ErrorRecord]::new(
            "NIOS WAPI $($sCache.HighestVersion) doesn't support schema queries",
            $null, [Management.Automation.ErrorCategory]::InvalidOperation, $null
        ))
    }

    # cache some base schema stuff that we'll potentially need later
    if (-not $sCache.SupportedVersions -or -not $sCache[$WAPIVersion]) {
        try {
            $schema = Invoke-IBWAPI -Query '?_schema' @opts -EA Stop
        } catch { $PsCmdlet.ThrowTerminatingError($_) }

        # set supported versions
        $sCache.SupportedVersions = $schema.supported_versions | Sort-Object @{E={[Version]$_}}
        Write-Debug "Set supported versions: $($sCache.SupportedVersions -join ', ')"

        # set supported objects for this version
        $sCache[$WAPIVersion] = $schema.supported_objects | Sort-Object
        Write-Debug "Set supported objects for $($WAPIVersion): $($sCache[$WAPIVersion] -join ', ')"
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
        Write-Debug "ObjectType: $ObjectType"
        $objMatches = $sCache[$WAPIVersion] | ForEach-Object { if ($_ -like $ObjectType) { $_ } }
        Write-Debug "Matches: $($objMatches.Count)"
        if ($objMatches.count -gt 1) {
            # multiple matches
            $message = "Multiple object matches found for $($ObjectType)"
            if ($Raw) {
                $PSCmdlet.ThrowTerminatingError([Management.Automation.ErrorRecord]::new(
                    $message,$null, [Management.Automation.ErrorCategory]::LimitsExceeded, $null
                ))
            }
            Write-Output "$($message):"
            $objMatches | ForEach-Object { Write-Output $_ }
            return
        }
        elseif ($objMatches.count -eq 0 ) {
            Write-Debug "Retrying matches with implied wildcards"
            # retry matching with implied wildcards
            $objMatches = $sCache[$WAPIVersion] | ForEach-Object { if ($_ -like "*$ObjectType*") { $_ } }
            if ($objMatches.count -gt 1) {
                # multiple matches
                $message = "Multiple object matches found for $($ObjectType)"
                if ($Raw) {
                    $PSCmdlet.ThrowTerminatingError([Management.Automation.ErrorRecord]::new(
                        $message,$null, [Management.Automation.ErrorCategory]::LimitsExceeded, $null
                    ))
                }
                Write-Output "$($message):"
                $objMatches | ForEach-Object { Write-Output $_ }
                return
            }
            elseif ($objMatches.count -eq 0) {
                # no matches, even with wildcards
                $message = "No matches found for $($ObjectType)"
                if ($Raw) {
                    $PSCmdlet.ThrowTerminatingError([Management.Automation.ErrorRecord]::new(
                        $message,$null, [Management.Automation.ErrorCategory]::ObjectNotFound, $null
                    ))
                }
                else { Write-Warning $message }
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
    $query = '{0}?_schema=1' -f $ObjectType
    if ([Version]$sCache.HighestVersion -ge [Version]'2.6') {
        $query += "&_schema_version=2&_schema_searchable=1&_get_doc=1"
    }

    try {
        $schema = Invoke-IBWAPI -Query $query @opts -EA Stop
    } catch { $PsCmdlet.ThrowTerminatingError($_) }

    # check for the switches that will prevent additional output
    if ($Raw -or $LaunchHTML) {
        # return the schema object directly, if asked
        if ($Raw) { Write-Output $schema }
        # launch a browser window to the object's full docs
        if ($LaunchHTML) {
            $docBase = $script:WAPIDocTemplate -f $WAPIHost
            if ([String]::IsNullOrWhiteSpace($ObjectType)) {
                Start-Process "$($docBase)index.html"
            } else {
                Start-Process "$($docBase)objects/$($ObjectType.Replace(':','.')).html"
            }
        }
        return
    }

    function BlankLine() { Write-Output '' }
    function PrettifySupports([string]$supports) {
        # The 'supports' property of a schema Field is a lower cases string
        # containing one or more of r,w,u,d,s for the supported operations of
        # that field. Most, but not all, are in a standard order. There are
        # instances of things like 'wu' vs 'uw'. We want to standardize the
        # order (RWUSD), uppercase the letters, and insert spaces for the operations
        # not included in the list.
        $ret = ''
        'R','W','U','D','S' | ForEach-Object {
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
                $type = ($field.type | ForEach-Object { "$_[]" }) -join ' | '
            } else {
                $type = $field.type -join '|'
            }
        }

        $type
    }

    if (!$schema.type) {
        # base schema object
        BlankLine
        Write-Output "Requested Version: $($schema.requested_version)"
        BlankLine
        Write-Output "Supported Versions:"
        BlankLine
        Write-Output ($schema.supported_versions | Sort-Object @{E={[Version]$_}} | Format-Columns -prop {$_} -col 4)
        BlankLine
        Write-Output "Supported Objects:"
        BlankLine
        Write-Output ($schema.supported_objects | Format-Columns -prop {$_})
        BlankLine
    }
    else {
        # display the top level object info
        $typeStr = "$($schema.type) (WAPI $($schema.version))"
        BlankLine
        Write-Output 'OBJECT'
        Write-Output ($typeStr | Split-Str -Indent 4)
        if ($schema.restrictions) {
            BlankLine
            Write-Output 'RESTRICTIONS'
            Write-Output ("$($schema.restrictions -join ', ')" | Split-Str -Indent 4)
        }
        if ($schema.cloud_additional_restrictions) {
            BlankLine
            Write-Output 'CLOUD RESTRICTIONS'
            Write-Output ("$($schema.cloud_additional_restrictions -join ', ')" | Split-Str -Indent 4)
        }

        # With _schema_version=2, functions are returned in the normal
        # list of fields. But we want to split those out and display them differently.
        $fieldList = @($schema.fields | Where-Object { $_.wapi_primitive -ne 'funccall' })
        $funcList  = @($schema.fields | Where-Object { $_.wapi_primitive -eq 'funccall' })

        # filter the fields if specified
        if ($Fields.count -gt 0) {
            $fieldList = @($fieldList | Where-Object {
                $name = $_.name
                ($Fields | ForEach-Object { $name -like $_ }) -contains $true
            })
        }
        # filter fields that don't include at least one specified Operation unless no operations were specified
        if ($Operations.count -gt 0) {
            $fieldList = @($fieldList | Where-Object {
                $supports = $_.supports
                ($Operations | ForEach-Object { $supports -like "*$_*"}) -contains $true
            })
        }
        # filter the functions if specified
        if ($Functions.count -gt 0) {
            $funcList = @($funcList | Where-Object {
                $name = $_.name
                ($Functions | ForEach-Object { $name -like $_ }) -contains $true
            })
        }

        if ($fieldList.count -gt 0 -and !$NoFields) {

            if ($Detailed) {
                # Display the detailed view

                BlankLine
                Write-Output 'FIELDS'

                # loop through fields alphabetically
                $fieldList | Sort-Object name | ForEach-Object {

                    Write-Output ("$($_.name) <$(PrettifyType $_)>" | Split-Str -Indent 4)

                    if ($_.doc) {
                        Write-Output ($_.doc | Split-Str -Indent 8)
                    }
                    BlankLine

                    Write-Output ("Supports: $(PrettifySupportsDetail $_.supports)" | Split-Str -Indent 8)

                    if ($_.overridden_by) {
                        Write-Output ("Overridden By: $($_.overridden_by)" | Split-Str -Indent 8)
                    }
                    if ($_.standard_field) {
                        Write-Output ("This field is part of the base object." | Split-Str -Indent 8)
                    }
                    if ($_.supports_inline_funccall) {
                        Write-Output ("This field supports inline function calls. See full docs for more detail." | Split-Str -Indent 8)
                    }
                    if ($_.searchable_by) {
                        BlankLine
                        Write-Output ("This field is available for search via:" | Split-Str -Indent 8)
                        if ($_.searchable_by -like '*=*') { Write-Output ("'=' (exact equality)" | Split-Str -Indent 12) }
                        if ($_.searchable_by -like '*!*') { Write-Output ("'!=' (negative equality)" | Split-Str -Indent 12) }
                        if ($_.searchable_by -like '*:*') { Write-Output ("':=' (case insensitive search)" | Split-Str -Indent 12) }
                        if ($_.searchable_by -like '*~*') { Write-Output ("'~=' (regular expression)" | Split-Str -Indent 12) }
                        if ($_.searchable_by -like '*<*') { Write-Output ("'<=' (less than or equal to)" | Split-Str -Indent 12) }
                        if ($_.searchable_by -like '*>*') { Write-Output ("'>=' (greater than or equal to)" | Split-Str -Indent 12) }
                    }

                    # At this point, the only other thing to potentially deal with is if this field is
                    # a struct. If so, there will be a sub-schema object with it's own set of fields. But
                    # each of those fields might also be a struct with even more sub-schemas, potentially going
                    # 3+ levels deep. Even the HTML docs don't try to cram all that into a field's description.
                    # They stick with links to the struct details.

                    # Unfortunately, the schema queries don't support querying structs directly. So in order to
                    # fake making something like that work, we would need to basically cache struct definitions
                    # (per WAPI version) as they're queried. Maybe have some way to pre-cache all the structs for
                    # a particular version by whipping through the supported object types?

                    # In any case, it's a non-trivial task for another day. And I don't want it to delay the schema
                    # querying release.

                    BlankLine
                }

            } else {
                # Display the simple view

                # get the length of the longest field name so we can make sure not to truncate that column
                $nameMax = [Math]::Max(($fieldList.name | Sort-Object -desc @{E={$_.length}} | Select-Object -first 1).length + 1, 6)
                # get the length of the longest type name (including potential array brackets) so we can
                # make sure not to truncate that column
                $typeMax = [Math]::Max(($fieldList.type | Sort-Object -desc @{E={$_.length}} | Select-Object -first 1).length + 3, 5)

                $format = "{0,-$nameMax}{1,-$typeMax}{2,-9}{3,-5}{4,-6}"
                BlankLine
                Write-Output ($format -f 'FIELD','TYPE','SUPPORTS','BASE','SEARCH')
                Write-Output ($format -f '-----','----','--------','----','------')

                # loop through fields alphabetically
                $fieldList | Sort-Object @{E='name';Desc=$false} | ForEach-Object {

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
                    Write-Output ($format -f $_.name,$_.type[0],(PrettifySupports $_.supports),$base,$_.searchable_by)

                    # write additional types on their own line
                    if ($_.type.count -gt 1) {
                        for ($i=1; $i -lt $_.type.count; $i++) {
                            Write-Output "$(''.PadRight($nameMax))$($_.type[$i])"
                        }
                    }
                }
            } # end simple field view
        } # end fields

        if ($funcList.count -gt 0 -and !$NoFunctions) {

            BlankLine
            Write-Output "FUNCTIONS"

            if ($Detailed) {

                $funcList | ForEach-Object {
                    BlankLine
                    Write-Output '    ----------------------------------------------------------'
                    Write-Output ($_.name | Split-Str -Indent 4)
                    Write-Output '    ----------------------------------------------------------'
                    if ($_.doc) {
                        Write-Output ($_.doc | Split-Str -Indent 8)
                    }
                    if ($_.schema.input_fields.count -gt 0) {
                        BlankLine
                        Write-Output ("INPUTS" | Split-Str -Indent 4)
                        foreach ($field in $_.schema.input_fields) {
                            BlankLine
                            Write-Output ("$($field.name) <$(PrettifyType $field)>" | Split-Str -Indent 8)
                            Write-Output ($field.doc | Split-Str -Indent 12)
                        }
                    }
                    if ($_.schema.output_fields.count -gt 0) {
                        BlankLine
                        Write-Output ("OUTPUTS" | Split-Str -Indent 4)
                        foreach ($field in $_.schema.output_fields) {
                            BlankLine
                            Write-Output ("$($field.name) <$(PrettifyType $field)>" | Split-Str -Indent 8)
                            Write-Output ($field.doc | Split-Str -Indent 12)
                        }
                    }

                }

            } else {

                $funcList | ForEach-Object {
                    $funcListtr = "$($_.name)($($_.schema.input_fields.name -join ', '))"
                    if ($_.schema.output_fields.count -gt 0) {
                        $funcListtr += " => $($_.schema.output_fields.name -join ', ')"
                    }
                    Write-Output ($funcListtr | Split-Str -Indent 4)
                }

            } # end simple function view
        } # end functions

        BlankLine
    }
}
