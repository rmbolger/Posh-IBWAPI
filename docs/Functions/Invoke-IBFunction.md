---
external help file: Posh-IBWAPI-help.xml
Module Name: Posh-IBWAPI
online version: https://docs.dvolve.net/Posh-IBWAPI/v4/Functions/Invoke-IBFunction/
schema: 2.0.0
---

# Invoke-IBFunction

## Synopsis

Call a WAPI function

## Syntax

```powershell
Invoke-IBFunction [-ObjectRef] <String> [-FunctionName] <String> [[-FunctionArgs] <PSObject>]
 [[-ProfileName] <String>] [[-WAPIHost] <String>] [[-WAPIVersion] <String>] [[-Credential] <PSCredential>]
 [-SkipCertificateCheck] [-WhatIf] [-Confirm] [<CommonParameters>]
```

## Description

This function allows you to call a WAPI function given a specific object reference and the function details.

## Examples

### Example 1: Restart grid services

```powershell
$grid = Get-IBObject -type grid
$restartArgs = @{restart_option='RESTART_IF_NEEDED'}
$grid | Invoke-IBFunction -name restartservices -args $restartArgs
```

Restart grid services if necessary.

## Parameters

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

### -FunctionArgs
An object with the required parameters for the function.

```yaml
Type: PSObject
Parameter Sets: (All)
Aliases: args

Required: False
Position: 3
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -FunctionName
The name of the function to call.

```yaml
Type: String
Parameter Sets: (All)
Aliases: name

Required: True
Position: 2
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

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
The fully qualified DNS name or IP address of the Infoblox WAPI endpoint (usually the grid master). This parameter is required if not already set using Set-IBConfig.

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

## Related Links

[Get-IBObject](Get-IBObject.md)
