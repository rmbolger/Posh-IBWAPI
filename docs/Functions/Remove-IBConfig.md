---
external help file: Posh-IBWAPI-help.xml
Module Name: Posh-IBWAPI
online version: https://docs.dvolve.net/Posh-IBWAPI/v4/Functions/Remove-IBConfig/
schema: 2.0.0
---

# Remove-IBConfig

## Synopsis

Remove a WAPI connection profile.

## Syntax

### Specific
```powershell
Remove-IBConfig [[-ProfileName] <String>] [<CommonParameters>]
```

### All
```powershell
Remove-IBConfig [-AllProfiles] [<CommonParameters>]
```

## Description

When called with no parameters, the currently active connection profile will be removed.
When called with -ProfileName, the specified profile will be removed.
When called with -AllProfiles, all profiles will be removed.

## Examples

### Example 1: Remove current profile

```powershell
Remove-IBConfig
```

Remove the currently active connection profile.

### Example 2: Remove all profiles

```powershell
Remove-IBConfig -AllHosts
```

Remove all connection profiles.

## Parameters

### -ProfileName
The name of the profile to remove.

```yaml
Type: String
Parameter Sets: Specific
Aliases: name

Required: False
Position: 1
Default value: None
Accept pipeline input: True (ByPropertyName, ByValue)
Accept wildcard characters: False
```

### -AllProfiles
If set, all profiles will be removed.

```yaml
Type: SwitchParameter
Parameter Sets: All
Aliases:

Required: True
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## Related Links

[Set-IBConfig](Set-IBConfig.md)
