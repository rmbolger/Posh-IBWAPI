---
external help file: Posh-IBWAPI-help.xml
Module Name: Posh-IBWAPI
online version: https://docs.dvolve.net/Posh-IBWAPI/v4/Functions/Set-IBObject/
schema: 2.0.0
---

# Set-IBObject

## Synopsis

Modify an object in Infoblox.

## Syntax

### ObjectOnly
```powershell
Set-IBObject -IBObject <PSObject> [-ReturnFields <String[]>] [-ReturnBase] [-BatchMode]
 [-BatchGroupSize <Int32>] [-WAPIHost <String>] [-WAPIVersion <String>] [-Credential <PSCredential>]
 [-SkipCertificateCheck] [-ProfileName <String>] [-WhatIf] [-Confirm] [<CommonParameters>]
```

### RefAndTemplate
```powershell
Set-IBObject -ObjectRef <String> -TemplateObject <PSObject> [-ReturnFields <String[]>] [-ReturnBase]
 [-BatchMode] [-BatchGroupSize <Int32>] [-WAPIHost <String>] [-WAPIVersion <String>]
 [-Credential <PSCredential>] [-SkipCertificateCheck] [-ProfileName <String>] [-WhatIf] [-Confirm]
 [<CommonParameters>]
```

## Description

Modify an object by specifying its object reference and a PSObject with the fields to change.

## Examples

### Example 1: Update host record

```powershell
$myhost = Get-IBObject -ObjectType 'record:host' -Filter 'name=myhost' -ReturnFields 'comment'
$myhost.comment = 'new comment'
Set-IBObject -ObjectRef $myhost._ref -IBObject $myhost
```

Search for a host record called 'myhost', update the comment field, and save it.

### Example 2: Update multiple host records

```powershell
$toChange = Get-IBObject -type 'record:host' -Filter 'name~=oldname' -fields 'name'
$toChange | %{ $_.name = $_.name.Replace('oldname','newname'); $_ } | Set-IBObject
```

Find all hosts with 'oldname' in the name, change the references to 'newname', and send them through the pipeline to Set-IBObject for saving.

### Example 3: Change multiple comments

```powershell
$myhosts = Get-IBObject 'record:host' -Filter 'comment=web server'
$myhosts | Set-IBObject -TemplateObject @{comment='db server'}
```

Find all host records with comment 'web server' and change them to 'db server' with a manually created template

## Parameters

### -BatchGroupSize
The number of objects that should be sent in each group when -BatchMode is specified. The default is 1000.

```yaml
Type: Int32
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -BatchMode
If specified, objects passed via pipeline will be batched together into groups and sent as a single WAPI call per group instead of a WAPI call per object. This can increase performance but if any of the individual calls fail, the whole group is cancelled.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -Credential
Username and password for the Infoblox appliance. This parameter is required unless it was already set using Set-IBConfig.

```yaml
Type: PSCredential
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -IBObject
An object with the fields to be modified. This must include a '_ref' with the object reference string to modify. All included fields will be modified even if they are empty.

```yaml
Type: PSObject
Parameter Sets: ObjectOnly
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: True (ByValue)
Accept wildcard characters: False
```

### -ObjectRef
Object reference string. This is usually found in the "_ref" field of returned objects.

```yaml
Type: String
Parameter Sets: RefAndTemplate
Aliases: _ref, ref

Required: True
Position: Named
Default value: None
Accept pipeline input: True (ByPropertyName, ByValue)
Accept wildcard characters: False
```

### -ProfileName
The name of a specific config profile to use instead of the currently active one.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -ReturnBase
If specified, the standard fields for this object type will be returned in addition to the object reference and any additional fields specified by -ReturnFields.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases: base, ReturnBaseFields

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -ReturnFields
The set of fields that should be returned in addition to the object reference.

```yaml
Type: String[]
Parameter Sets: (All)
Aliases: fields

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -SkipCertificateCheck
If set, SSL/TLS certificate validation will be disabled. Overrides value stored with Set-IBConfig.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -TemplateObject
An object with the fields to be modified. A '_ref' field in this object will be ignored. This is only usable with a separate -ObjectRef parameter.

```yaml
Type: PSObject
Parameter Sets: RefAndTemplate
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -WAPIHost
The fully qualified DNS name or IP address of the Infoblox WAPI endpoint (usually the grid master).
This parameter is required if not already set using Set-IBConfig.

```yaml
Type: String
Parameter Sets: (All)
Aliases: host

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -WAPIVersion
The version of the Infoblox WAPI to make calls against (e.g. '2.2').

```yaml
Type: String
Parameter Sets: (All)
Aliases: version

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Confirm
Prompts you for confirmation before running the cmdlet.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases: cf

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -WhatIf
Shows what would happen if the cmdlet runs. The cmdlet is not run.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases: wi

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## Outputs

### PSCustomObject
The object reference string of the modified item or a custom object if -ReturnFields or -ReturnBase was used.

## Related Links

[Get-IBObject](Get-IBObject.md)
