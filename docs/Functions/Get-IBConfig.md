---
external help file: Posh-IBWAPI-help.xml
Module Name: Posh-IBWAPI
online version: https://docs.dvolve.net/Posh-IBWAPI/v4/Functions/Get-IBConfig/
schema: 2.0.0
---

# Get-IBConfig

## Synopsis

Get one or more connection profiles.

## Syntax

### Specific (Default)
```powershell
Get-IBConfig [[-ProfileName] <String>] [<CommonParameters>]
```

### List
```powershell
Get-IBConfig [-List] [<CommonParameters>]
```

## Description

When calling this function with no parameters, the currently active profile will be returned.
These values will be used by related function calls to the Infoblox API unless they are overridden by the function's own parameters.

When called with -ProfileName, the profile matching that name will be returned.
When called with -List, all profiles will be returned.

## Examples

### Example 1: Current profile

```powershell
Get-IBConfig
```

Get the current connection profile.

### Example 2: List all profiles

```powershell
Get-IBConfig -List
```

Get all connection profiles.

## Parameters

### -ProfileName
The name of the connection profile to return.

```yaml
Type: String
Parameter Sets: Specific
Aliases:

Required: False
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -List
If set, list all connection profiles currently stored.

```yaml
Type: SwitchParameter
Parameter Sets: List
Aliases:

Required: True
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## Outputs

### PoshIBWAPI.IBConfig
A config object

## Related Links

[Set-IBConfig](Set-IBConfig.md)

[Get-IBObject](Get-IBObject.md)
