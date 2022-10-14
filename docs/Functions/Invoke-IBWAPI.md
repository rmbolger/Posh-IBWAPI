---
external help file: Posh-IBWAPI-help.xml
Module Name: Posh-IBWAPI
online version: https://docs.dvolve.net/Posh-IBWAPI/v4/Functions/Invoke-IBWAPI/
schema: 2.0.0
---

# Invoke-IBWAPI

## Synopsis

Send a request to the Infoblox WAPI (REST API).

## Syntax

### Uri (Default)
```powershell
Invoke-IBWAPI [-Uri] <Uri> [-Method <WebRequestMethod>] [-Credential <PSCredential>] [-Body <Object>]
 [-ContentType <String>] [-OutFile <String>] [-SessionVariable <String>] [-WebSession <WebRequestSession>]
 [-SkipCertificateCheck] [-WhatIf] [-Confirm] [<CommonParameters>]
```

### HostVersion
```powershell
Invoke-IBWAPI [-WAPIHost] <String> [-WAPIVersion] <String> [-Query] <String> [-Method <WebRequestMethod>]
 [-Credential <PSCredential>] [-Body <Object>] [-ContentType <String>] [-OutFile <String>]
 [-SessionVariable <String>] [-WebSession <WebRequestSession>] [-SkipCertificateCheck] [-WhatIf] [-Confirm]
 [<CommonParameters>]
```

## Description

This function is largely just a wrapper around Invoke-RestMethod that supports trapping and exposing syntax errors with the WAPI and the ability to ignore certificate validation.
It is what all of the *-IBObject functions use under the hood and shouldn't be necessary to call directly most of the time.

## Examples

### Example 1: Get network objects

```powershell
Invoke-IBWAPI -Uri 'https://gridmaster.example.com/wapi/v2.2/network' -Credential (Get-Credential)
```

Retrieve the list of network objects from the grid master using interactive credentials.

## Parameters

### -Body
The body of the request. This is usually either a JSON string or an object that will be converted to JSON automatically by the function. If the ContentType parameter is used, this function will not attempt to automatically convert the Body to JSON.

```yaml
Type: Object
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -ContentType
The Content-Type header for the request. Default is 'application/json; charset=utf-8'. If specified along with a Body parameter, the Body will not be modified before being passed to the WAPI.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: Application/json; charset=utf-8
Accept pipeline input: False
Accept wildcard characters: False
```

### -Credential
Username and password for the Infoblox appliance. This parameter is required unless -WebSession is specified.

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

### -Method
The HTTP method to use in the request. Default is GET.

```yaml
Type: WebRequestMethod
Parameter Sets: (All)
Aliases:
Accepted values: Default, Get, Head, Post, Put, Delete, Trace, Options, Merge, Patch

Required: False
Position: Named
Default value: Get
Accept pipeline input: False
Accept wildcard characters: False
```

### -OutFile
Specifies the output file that this cmdlet saves the response body. Enter a path and file name. If you omit the path, the default is the current location.

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

### -Query
The object type or reference being queried along with any URI querystring parameters. (e.g. 'network' or 'network?comment=Production')

```yaml
Type: String
Parameter Sets: HostVersion
Aliases:

Required: True
Position: 3
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -SessionVariable
Specifies a variable for which this cmdlet creates a web request session and saves it in the value. Enter a variable name without the dollar sign ($) symbol.

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
If set, SSL/TLS certificate validation will be disabled.

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

### -Uri
The full Uri of the WAPI endpoint. (e.g. https://gridmaster.example.com/wapi/v2.2/network)

```yaml
Type: Uri
Parameter Sets: Uri
Aliases:

Required: True
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -WAPIHost
The fully qualified DNS name or IP address of the Infoblox WAPI endpoint (usually the grid master).

```yaml
Type: String
Parameter Sets: HostVersion
Aliases: host

Required: True
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -WAPIVersion
The version of the Infoblox WAPI to make calls against (e.g. '2.2').

```yaml
Type: String
Parameter Sets: HostVersion
Aliases: version

Required: True
Position: 2
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -WebSession
Specifies an existing WebSession object to use with the request. If specified, the SessionVariable parameter will be ignored.

```yaml
Type: WebRequestSession
Parameter Sets: (All)
Aliases:

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

[New-IBObject](New-IBObject.md)

[Get-IBObject](Get-IBObject.md)
