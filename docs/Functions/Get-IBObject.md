---
external help file: Posh-IBWAPI-help.xml
Module Name: Posh-IBWAPI
online version: https://docs.dvolve.net/Posh-IBWAPI/v4/Functions/Get-IBObject/
schema: 2.0.0
---

# Get-IBObject

## Synopsis

Retrieve objects from the Infoblox database.

## Syntax

### ByType (Default)
```powershell
Get-IBObject [-ObjectType] <String> [-Filter <Object>] [-MaxResults <Int32>] [-PageSize <Int32>]
 [-ReturnFields <String[]>] [-ReturnBaseFields] [-ReturnAllFields] [-ProxySearch] [-WAPIHost <String>]
 [-WAPIVersion <String>] [-Credential <PSCredential>] [-SkipCertificateCheck] [-ProfileName <String>]
 [<CommonParameters>]
```

### ByTypeNoPaging
```powershell
Get-IBObject [-ObjectType] <String> [-Filter <Object>] [-NoPaging] [-ReturnFields <String[]>]
 [-ReturnBaseFields] [-ReturnAllFields] [-ProxySearch] [-WAPIHost <String>] [-WAPIVersion <String>]
 [-Credential <PSCredential>] [-SkipCertificateCheck] [-ProfileName <String>] [<CommonParameters>]
```

### ByRef
```powershell
Get-IBObject [-ObjectRef] <String> [-BatchMode] [-ReturnFields <String[]>] [-ReturnBaseFields]
 [-ReturnAllFields] [-ProxySearch] [-WAPIHost <String>] [-WAPIVersion <String>] [-Credential <PSCredential>]
 [-SkipCertificateCheck] [-ProfileName <String>] [<CommonParameters>]
```

## Description

Query a specific object's details by specifying ObjectRef or search for a set of objects using ObjectType and optional Filter arguments.
For large result sets, query pagination will automatically be used to fetch all results.
The result count can be limited with the -MaxResults parameter.

## Examples

### Example 1: Get specific object

```powershell
Get-IBObject -ObjectRef 'record:host/XxXxXxXxXxXxXxX'
```

Get the basic fields for a specific Host record.

### Example 2: Get A records with filters

```powershell
Get-IBObject 'record:a' -Filter 'name~=.*\.example.com' -MaxResults 100 -ReturnFields 'comment' -ReturnBaseFields
```

Get the first 100 A records in the example.com DNS zone and return the comment field in addition to the basic fields.

### Example 3: Get network containers within another container

```powershell
Get-IBObject -ObjectType 'networkcontainer' -Filter 'network_container=192.168.1.0/19'
```

Get all network containers that have a parent container of 192.168.1.0/19

### Example 4: Get networks within a network container

```powershell
Get-IBObject -ObjectType 'network' -Filter 'network_container=192.168.1.0/20'
```

Get all networks that have a parent container of 192.168.1.0/20

## Parameters

### -ObjectType
Object type string. (e.g. network, record:host, range)

```yaml
Type: String
Parameter Sets: ByType, ByTypeNoPaging
Aliases: type

Required: True
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -ObjectRef
Object reference string. This is usually found in the "_ref" field of returned objects.

```yaml
Type: String
Parameter Sets: ByRef
Aliases: _ref, ref

Required: True
Position: 1
Default value: None
Accept pipeline input: True (ByPropertyName, ByValue)
Accept wildcard characters: False
```

### -BatchMode
If specified, objects passed via pipeline will be batched together into groups and sent as a single WAPI call per group instead of a WAPI call per object. This can increase performance but if any of the individual calls fail, the whole group is cancelled.

```yaml
Type: SwitchParameter
Parameter Sets: ByRef
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -Filter
A string array of search filter conditions (e.g. "name%7E=myhost","ipv4addr=10.10.10.10") or hashtable (e.g. @{'name~'='myhost';ipv4addr='10.10.10.10'}). All conditions must be satisfied to match an object.
String based filters must be properly URL encoded. Hashtable filters will be automatically URL encoded.
See Infoblox WAPI documentation for advanced usage details.

```yaml
Type: Object
Parameter Sets: ByType, ByTypeNoPaging
Aliases: Filters

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -MaxResults
If set to a positive number, the results list will be truncated to that number if necessary. If set to a negative number and the results would exceed the absolute value, an error is thrown.

```yaml
Type: Int32
Parameter Sets: ByType
Aliases:

Required: False
Position: Named
Default value: 2147483647
Accept pipeline input: False
Accept wildcard characters: False
```

### -PageSize
The number of results to retrieve per request when auto-paging large result sets. Defaults to 1000. Set this lower if you have very large results that are causing errors with ConvertTo-Json.

```yaml
Type: Int32
Parameter Sets: ByType
Aliases:

Required: False
Position: Named
Default value: 1000
Accept pipeline input: False
Accept wildcard characters: False
```

### -NoPaging
If specified, automatic paging will not be used. This is occasionally necessary for some object type queries that return a single object reference such as dhcp:statistics.

```yaml
Type: SwitchParameter
Parameter Sets: ByTypeNoPaging
Aliases:

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

### -ReturnBaseFields
If specified, the standard fields for this object type will be returned in addition to the object reference and any additional fields specified by -ReturnFields. If -ReturnFields is not used, this defaults to $true.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases: base

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -ReturnAllFields
If specified, all readable fields will be returned for the object. This switch relies on Get-IBSchema and as such requires WAPI 1.7.5+. Because of the additional web requests necessary to make this work, it is also not recommended for performance critical code.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases: all

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -ProxySearch
If specified, the request is redirected to Grid manager for processing.

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
Position: Named
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
Position: Named
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

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## Outputs

### PSCustomObject
Zero or more objects found by the search or object reference. If an object reference is specified that doesn't exist, an error will be thrown.

## Related Links

[Set-IBConfig](Set-IBConfig.md)
