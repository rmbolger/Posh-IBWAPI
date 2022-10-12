---
external help file: Posh-IBWAPI-help.xml
Module Name: Posh-IBWAPI
online version: https://docs.dvolve.net/Posh-IBWAPI/v4/Functions/Send-IBFile/
schema: 2.0.0
---

# Send-IBFile

## Synopsis

Upload a file to Infoblox using one of the fileop upload functions.

## Syntax

```powershell
Send-IBFile [-FunctionName] <String> [-Path] <String> [-FunctionArgs <Hashtable>] [-ObjectRef <String>]
 [-OverrideTransferHost] [-ProfileName <String>] [-WAPIHost <String>] [-WAPIVersion <String>]
 [-Credential <PSCredential>] [-SkipCertificateCheck] [<CommonParameters>]
```

## Description

This is a wrapper around the various fileop functions that allow data import into Infoblox.

## Examples

### Example 1: Upload CA certificate

```powershell
Send-IBFile uploadcertificate .\ca.pem -FunctionArgs @{certificate_usage='EAP_CA'}
```

Upload a trusted CA certificate to the grid.

## Parameters

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

### -FunctionArgs
A hashtable with the required parameters for the function. NOTE: 'token' parameters are handled automatically and can be ignored.

```yaml
Type: Hashtable
Parameter Sets: (All)
Aliases: args

Required: False
Position: Named
Default value: @{}
Accept pipeline input: False
Accept wildcard characters: False
```

### -FunctionName
The name of the fileop upload function to call.

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
Position: Named
Default value: Fileop
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

### -Path
The path to the file that will be uploaded for this call.

```yaml
Type: String
Parameter Sets: (All)
Aliases: PSPath

Required: True
Position: 2
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

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## Related Links

[Receive-IBFile](Receive-IBFile.md)
