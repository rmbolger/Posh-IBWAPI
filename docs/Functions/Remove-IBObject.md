---
external help file: Posh-IBWAPI-help.xml
Module Name: Posh-IBWAPI
online version: https://docs.dvolve.net/Posh-IBWAPI/v4/Functions/Remove-IBObject/
schema: 2.0.0
---

# Remove-IBObject

## Synopsis

Delete an object from Infoblox.

## Syntax

```powershell
Remove-IBObject [-ObjectRef] <String> [[-DeleteArgs] <String[]>] [-BatchMode] [[-WAPIHost] <String>]
 [[-WAPIVersion] <String>] [[-Credential] <PSCredential>] [-SkipCertificateCheck] [[-ProfileName] <String>]
 [-WhatIf] [-Confirm] [<CommonParameters>]
```

## Description

Specify an object reference to delete that object from the Infoblox database.

## Examples

### Example 1: Delete host record by name

```powershell
$myhost = Get-IBObject -ObjectType 'record:host' -Filter 'name=myhost'
Remove-IBObject -ObjectRef $myhost._ref
```

Search for a host record called 'myhost' and delete it.

### Example 2: Delete host record by comment

```powershell
$hostsToDelete = Get-IBObject 'record:host' -Filter 'comment=decommissioned'
$hostsToDelete | Remove-IBObject
```

Search for hosts with their comment set to 'decommissioned' and delete them all.

## Parameters

### -ObjectRef
Object reference string. This is usually found in the "_ref" field of returned objects.

```yaml
Type: String
Parameter Sets: (All)
Aliases: _ref, ref

Required: True
Position: 1
Default value: None
Accept pipeline input: True (ByPropertyName, ByValue)
Accept wildcard characters: False
```

### -DeleteArgs
Additional delete arguments for this object. For example, 'remove_associated_ptr=true' can be used with record:a. Requires WAPI 2.1+.

```yaml
Type: String[]
Parameter Sets: (All)
Aliases: args

Required: False
Position: 2
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

### -WAPIHost
The fully qualified DNS name or IP address of the Infoblox WAPI endpoint (usually the grid master). This parameter is required if not already set using Set-IBConfig.

```yaml
Type: String
Parameter Sets: (All)
Aliases: host

Required: False
Position: 3
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -WAPIVersion
The version of the Infoblox WAPI to make calls against (e.g. '2.2'). You may optionally specify 'latest' and the function will attempt to query the WAPI for the latest supported version.

```yaml
Type: String
Parameter Sets: (All)
Aliases: version

Required: False
Position: 4
Default value: None
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
Position: 5
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

### -ProfileName
The name of a specific config profile to use instead of the currently active one.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 6
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

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## Outputs

### String
The object reference string of the deleted item.

## Related Links

[New-IBObject](New-IBObject.md)

[Get-IBObject](Get-IBObject.md)
