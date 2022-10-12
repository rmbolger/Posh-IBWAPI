---
external help file: Posh-IBWAPI-help.xml
Module Name: Posh-IBWAPI
online version: https://docs.dvolve.net/Posh-IBWAPI/v4/Functions/Set-IBConfig/
schema: 2.0.0
---

# Set-IBConfig

## Synopsis

Save connection parameters to a profile to avoid needing to supply them to future functions.

## Syntax

```powershell
Set-IBConfig [[-ProfileName] <String>] [[-WAPIHost] <String>] [[-WAPIVersion] <String>]
 [[-Credential] <PSCredential>] [-SkipCertificateCheck] [[-NewName] <String>] [-NoSwitchProfile]
 [<CommonParameters>]
```

## Description

Rather than specifying the same common parameter values to most of the function calls in this module, you can pre-set them with this function instead. They will be used automatically by other functions that support them unless overridden by the function's own parameters.

Calling this function with a profile name will update that profile's values and switch the current profile to the specified one unless -NoSwitchProfile is used. When a profile name is not specified, the current profile's values will be updated with any specified changes.

## Examples

### Example 1: Switch profiles

```powershell
Set-IBConfig -ProfileName 'gm-admin'
```

Switch to the 'gm-admin' profile, but make no changes.

### Example 2: Create or update a profile

```powershell
Set-IBConfig -ProfileName 'gm-admin' -WAPIHost gm.example.com -WAPIVersion 2.2 -Credential (Get-Credential) -SkipCertificateCheck
```

Create or update the 'gm-admin' profile with all basic connection parameters for an Infoblox WAPI connection. This will also prompt for the credentials and skip certificate validation.

### Example 3: Update the current profile

```powershell
Set-IBConfig -WAPIVersion 2.5
```

Update the current profile to WAPI version 2.5

## Parameters

### -Credential
Username and password for the Infoblox appliance.

```yaml
Type: PSCredential
Parameter Sets: (All)
Aliases:

Required: False
Position: 4
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -NewName
A new name that this config profile should be renamed to.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 5
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -NoSwitchProfile
If set, the current profile will not switch to the specified -ProfileName if different.

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
The name of the profile to create or modify.

```yaml
Type: String
Parameter Sets: (All)
Aliases: name

Required: False
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -SkipCertificateCheck
If set, SSL/TLS certificate validation will be disabled for this profile.

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

```yaml
Type: String
Parameter Sets: (All)
Aliases: host

Required: False
Position: 2
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
Position: 3
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## Related Links

[Get-IBConfig](Get-IBConfig.md)

[Invoke-IBWAPI](Invoke-IBWAPI.md)
