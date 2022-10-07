---
external help file: Posh-IBWAPI-help.xml
Module Name: Posh-IBWAPI
online version: https://docs.dvolve.net/Posh-IBWAPI/v4/Functions/Get-IBSchema/
schema: 2.0.0
---

# Get-IBSchema

## Synopsis

Query the schema of an object or the base appliance.

## Syntax

```powershell
Get-IBSchema [[-ObjectType] <String>] [-Raw] [-LaunchHTML] [[-Fields] <String[]>] [[-Operations] <String[]>]
 [-NoFields] [[-Functions] <String[]>] [-NoFunctions] [-Detailed] [[-WAPIHost] <String>]
 [[-WAPIVersion] <String>] [[-Credential] <PSCredential>] [-SkipCertificateCheck] [[-ProfileName] <String>]
 [<CommonParameters>]
```

## Description

Without any parameters, this function will return the base appliance schema object which includes the list of supported WAPI versions and object types. Providing an -ObjectType will return the schema object for that type which includes a list of supported fields and functions.

## Examples

### Example 1: Root schema

```powershell
Get-IBSchema
```

Get the root schema object.

### Example 2: Host record schema

```powershell
Get-IBSchema record:host
```

Get the record:host schema object.

### Example 3: Host record schema raw object

```powershell
Get-IBSchema record:host -Raw
```

Get the record:host schema object in raw object form.

### Example 4: Specific fields from grid schema

```powershell
Get-IBSchema grid -Fields enable*,name
```

Get the grid schema object and only include the name field and fields that start with 'enable'.

### Example 5: Searchable fields from network schema

```powershell
Get-IBSchema network -Operations s -NoFunctions
```

Get the network schema object and only include fields that are searchable and skip function definitions.

## Parameters

### -ObjectType
Object type string. (e.g. network, record:host, range). Partial names and wildcards are supported. If the ObjectType parameter would match multiple objects, the list of matching objects will be returned.

```yaml
Type: String
Parameter Sets: (All)
Aliases: type

Required: False
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Raw
If set, the schema object will be returned as-is rather than pretty printing the output. All additional display parameters are ignored except -LaunchHTML.

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

### -LaunchHTML
If set, Powershell will attempt to launch a browser to the object's full HTML documentation page on the grid master. All additional display parameters are ignored except -Raw.

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

### -Fields
A list of Field names to include in the output. Wildcards are supported. This parameter is ignored if -NoFields is specified. If neither is specified, all Fields will be included.

```yaml
Type: String[]
Parameter Sets: (All)
Aliases:

Required: False
Position: 2
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Operations
A list of supported operation codes: r (read), w (write/create), u (update/set), s (search), d (delete). Only the Fields supporting at least one of these operations will be included in the output.
If not specified, all Fields will be included.

```yaml
Type: String[]
Parameter Sets: (All)
Aliases:

Required: False
Position: 3
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -NoFields
If set, the object's fields will not be included in the output.

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

### -Functions
A list of Function names to include in the output. Wildcards are supported. This parameter is ignored if -NoFunctions is specified. If neither is specified, all Functions will be included.

```yaml
Type: String[]
Parameter Sets: (All)
Aliases:

Required: False
Position: 4
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -NoFunctions
If set, the object's functions will not be included in the output.

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

### -Detailed
If set, detailed output is displayed for field and function information. Otherwise, a simplified view is displayed.

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
Position: 5
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -WAPIVersion
The version of the Infoblox WAPI to make calls against (e.g. '2.2'). This parameter is required if not already set using Set-IBConfig.

```yaml
Type: String
Parameter Sets: (All)
Aliases: version

Required: False
Position: 6
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
Position: 7
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
Position: 8
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## Related Links

[Get-IBObject](Get-IBObject.md)
