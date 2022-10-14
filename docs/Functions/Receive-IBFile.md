---
external help file: Posh-IBWAPI-help.xml
Module Name: Posh-IBWAPI
online version: https://docs.dvolve.net/Posh-IBWAPI/v4/Functions/Receive-IBFile/
schema: 2.0.0
---

# Receive-IBFile

## Synopsis

Download a file from a fileop function

## Syntax

```powershell
Receive-IBFile [-FunctionName] <String> [-OutFile] <String> [[-FunctionArgs] <IDictionary>]
 [[-ObjectRef] <String>] [-OverrideTransferHost] [[-ProfileName] <String>] [[-WAPIHost] <String>]
 [[-WAPIVersion] <String>] [[-Credential] <PSCredential>] [-SkipCertificateCheck] [<CommonParameters>]
```

## Description

This is a wrapper around the various fileop functions that allow data export from Infoblox.

## Examples

### Example 1: Download grid backup

```powershell
Receive-IBFile getgriddata .\backup.tar.gz -args @{type='BACKUP'}
```

Download a grid backup file using the 'getgriddata' fileop function.

### Example 2: Download CSV export

```powershell
Receive-IBFile csv_export .\host-records.csv -args @{_object='record:host'}
```

Download a CSV export of all host records using the 'csv_export' fileop function.

## Parameters

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

### -FunctionArgs
A hashtable with the required parameters for the function. NOTE: 'token' parameters are handled automatically and can be ignored.

```yaml
Type: IDictionary
Parameter Sets: (All)
Aliases: args

Required: False
Position: 3
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -FunctionName
The name of the fileop download function to call.

```yaml
Type: String
Parameter Sets: (All)
Aliases: name

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
Parameter Sets: (All)
Aliases: _ref, ref, ObjectType, type

Required: False
Position: 4
Default value: Fileop
Accept pipeline input: False
Accept wildcard characters: False
```

### -OutFile
Specifies the output file that this cmdlet saves the response body. Enter a path and file name. If you omit the path, the default is the current location.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: 2
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -OverrideTransferHost
If set, the hostname in the transfer URL returned by WAPI will be overridden to match the original WAPIHost if they don't already match. The SkipCertificateCheck switch will also be updated to match the passed in value instead of always being set to true for the call.

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
Position: 5
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
Position: 6
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## Related Links

[Invoke-IBFunction](Invoke-IBFunction.md)
