---
external help file: Posh-IBWAPI-help.xml
Module Name: Posh-IBWAPI
online version: https://docs.dvolve.net/Posh-IBWAPI/v4/Functions/New-IBObject/
schema: 2.0.0
---

# New-IBObject

## Synopsis

Create an object in Infoblox.

## Syntax

```powershell
New-IBObject [-ObjectType] <String> [-IBObject] <PSObject> [-ReturnField <String[]>] [-ReturnBase] [-BatchMode]
 [-BatchGroupSize <Int32>] [[-ProfileName] <String>] [[-WAPIHost] <String>] [[-WAPIVersion] <String>]
 [[-Credential] <PSCredential>] [-SkipCertificateCheck] [-WhatIf] [-Confirm] [<CommonParameters>]
```

## Description

Create an object by specifying the type and a PSObject with the required (and optional) fields for that type.

## Examples

### Example 1: New network

```powershell
$mynetwork = @{network='10.10.12.0/24';comment='my network'}
New-IBObject -ObjectType 'network' -IBObject $mynetwork
```

Create a basic new network with a comment.

### Example 2 New host with next IP

```powershell
$myhost = @{name='myhost';comment='my host';configure_for_dns=$false}
$myhost.ipv4addrs = @(@{ipv4addr='func:nextavailableip:10.10.12.0/24'})
New-IBObject 'record:host' $myhost -ReturnField 'comment','configure_for_dns' -ReturnBase
```

Create a new host record using an embedded function to get the next available IP in the specified network.
Returns the basic host fields plus the comment and configure_for_dns fields.

### Example 3: Multiple hosts with a template

```powershell
$template = @{name='dummy';configure_for_dns=$false;ipv4addrs=@(@{ipv4addr="func:nextavailableip:10.10.12.0/24"})}
1..5 | %{ $template.name = "myhost$_"; $template } | New-IBObject -ObjectType 'record:host' -BatchMode
```

Create a template object.
Then create 5 new host records with sequential names using the next 5 available IPs in the specified network based on the template.

### Example 4: New network with extensible attribute

```powershell
New-IBObject -ObjectType 'network' -IBObject @{network='192.168.1.0/24';extattrs=@{'Environment'=@{value='Production'}  } }
```

Create a network object that has extensibility attribute 'Environment' with value of 'Production'

### Example 5: New extensible attribute definition

```powershell
New-IBObject -ObjectType 'extensibleattributedef' -IBObject @{name='TestAttribute';flags = 'I';type='STRING';allowed_object_types='Network','NetworkContainer'}
```

Create an extensible attribute of STRING type with name of 'TestAttribute' enabled for object types IPV4 Network and IPV4 NetworkContainer and enable inheritance. Note that Network is a case sensitive string, this will not work if one would used 'network' or 'Networkcontainer'.

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
Position: 6
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -IBObject
A PSObject with the required fields for the specified type. Optional fields may also be included.

```yaml
Type: PSObject
Parameter Sets: (All)
Aliases:

Required: True
Position: 2
Default value: None
Accept pipeline input: True (ByValue)
Accept wildcard characters: False
```

### -ObjectType
Object type string. (e.g. network, record:host, range)

```yaml
Type: String
Parameter Sets: (All)
Aliases: type

Required: True
Position: 1
Default value: None
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
Position: 7
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -ReturnBase
If specified, the standard fields for this object type will be returned in addition to the object reference and any additional fields specified by -ReturnField.

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

### -ReturnField
The set of fields that should be returned in addition to the object reference.

```yaml
Type: String[]
Parameter Sets: (All)
Aliases: fields, ReturnFields

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

### -WAPIHost
The fully qualified DNS name or IP address of the Infoblox WAPI endpoint (usually the grid master).
This parameter is required if not already set using Set-IBConfig.

```yaml
Type: String
Parameter Sets: (All)
Aliases: host

Required: False
Position: 4
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
Position: 5
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
The object reference string of the created item or a custom object if -ReturnField or -ReturnBase was used.

## Related Links

[Get-IBObject](Get-IBObject.md)
