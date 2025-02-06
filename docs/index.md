title: Home

# Posh-IBWAPI

A PowerShell module to help with Infoblox automation via WAPI requests and functions. It is not intended to wrap every object into a set of custom cmdlets or strong types. Instead, it aims to hide the some of the tedious complexity in calling the Infoblox REST API via PowerShell.

## Features

- Automatic paging for large GET result sets *(Requires WAPI version 1.5+)*
- Automatic session handling
- `Receive-IBFile` and `Send-IBFile` wrappers for upload/download WAPI functions. [(Guide)](Guides/Using-IBFile-Functions.md)
- Optionally return all fields for an object without needing to specify each one individually *(Requires WAPI version 1.7.5+)*
- Use `Get-IBSchema` for Get-Help style querying of the WAPI object model *(Requires WAPI version 1.7.5+)*. [(Guide)](Guides/Using-Get-IBSchema.md)
- Error details in the body of HTTP 400 responses are exposed instead of being swallowed by Invoke-RestMethod.
- Optionally batch pipelined requests to increase performance.
- Optionally ignore certificate validation errors.
- Save connection profiles to use automatically with functions instead of supplying them to each call. Multiple profiles supported for multi-grid environments or differing credentials on the same grid.
- [SecretManagement](https://devblogs.microsoft.com/powershell/secretmanagement-and-secretstore-are-generally-available/) support for connection profiles. [(Guide)](Guides/Using-SecretManagement.md)
- Cloud friendly stateless mode supported via environment variables. [(Guide)](Guides/Stateless-Mode.md)
- Cross-platform [PowerShell](https://github.com/PowerShell/PowerShell) support

## Installation (Stable)

The latest release can found in the [PowerShell Gallery](https://www.powershellgallery.com/packages/Posh-IBWAPI/) or the [GitHub releases page](https://github.com/rmbolger/Posh-IBWAPI/releases). Installing is easiest from the gallery using `Install-Module`. *See [Installing PowerShellGet](https://docs.microsoft.com/en-us/powershell/scripting/gallery/installing-psget) if you run into problems with it.*

```powershell
# install for all users (requires elevated privs)
Install-Module -Name Posh-IBWAPI -Scope AllUsers

# install for current user
Install-Module -Name Posh-IBWAPI -Scope CurrentUser
```

!!! warning
    If you use PowerShell 5.1 or earlier, `Install-Module` may throw an error depending on your Windows and .NET version due to a change PowerShell Gallery made to their TLS settings. For more info and a workaround, see the [official blog post](https://devblogs.microsoft.com/powershell/powershell-gallery-tls-support/).

## Installation (Development)

[![Pester Tests badge](https://github.com/rmbolger/Posh-IBWAPI/workflows/Pester%20Tests/badge.svg)](https://github.com/rmbolger/Posh-IBWAPI/actions)

Use the following PowerShell command to install the latest *development* version from the git `main` branch. This method assumes a default [`PSModulePath`](https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_psmodulepath) environment variable and installs to the CurrentUser scope.

```powershell
iex (irm https://raw.githubusercontent.com/rmbolger/Posh-IBWAPI/main/instdev.ps1)
```

You can also download the source manually from GitHub and extract the `Posh-IBWAPI` folder to your desired module location.

## Quick Start

Every WAPI call needs a host, version, and credentials. Set them once using `Set-IBConfig` and you won't need to add them to every call. If your grid is still using self-signed certs, you may also need to use the `SkipCertificateCheck` parameter. In addition to standard version numbers like `'2.2'`, the `-WAPIVersion` parameter also accepts `'latest'` and will query the grid master for the latest supported version.

```powershell
Set-IBConfig -ProfileName 'mygrid' -WAPIHost 'gridmaster.example.com' `
    -WAPIVersion 'latest' -Credential (Get-Credential) -SkipCertificateCheck
```

Retrieve a set of objects using `Get-IBObject`. The only required parameter is `ObjectType`. Everything else like filters and return fields are optional.

```powershell
Get-IBObject 'record:host'
Get-IBObject 'record:host' -Filter @{'name~'='example\.com'} -MaxResults 10 -ReturnField 'extattrs'
```

If you're just exploring the WAPI object model, it can be helpful to convert the resulting objects back to JSON for readability.

```powershell
Get-IBObject 'record:host' | Select -First 1 | ConvertTo-Json -Depth 5
```

You may notice that all objects returned by Infoblox have a `_ref` field. That is known as the object reference and can be used in any function that accepts an `ObjectRef` parameter. In the case of `Get-IBObject`, it will return that specific object.

```powershell
Get-IBObject -ObjectRef 'record:host/asdfqwerasdfqwerasdfqwerasdfqwer'
```

Create a new object with `New-IBObject` by supplying the object type and an object with the minimum required fields defined. Embedded WAPI functions work just fine here.

```powershell
# Build the record:host object we want to create.
# NOTE: An error will be thrown if the example.com DNS zone doesn't
# exist in Infoblox
$newhost = @{
    name = 'web1.example.com'
    ipv4addrs = @(
        @{ ipv4addr = '10.10.10.1' }
    )
    comment = 'web server'
}

# Create the object
New-IBObject -ObjectType 'record:host' -IBObject $newhost

# Modify the object so we can make another and this time use an
# embedded function to set the IP address.
$newhost.name = 'web2.example.com'
$newhost.ipv4addrs = @(
    @{ ipv4addr = 'func:nextavailableip:10.10.10.0/24'}
)
New-IBObject -ObjectType 'record:host' -IBObject $newhost
```

To modify an existing object, the easiest way is usually to get a copy of it, modify the copy, and save the result with `Set-IBObject`. *Be wary of objects that return read-only fields. You need to strip them out before saving or an error will be thrown.*

```powershell
# Get a copy of the host
$myhost = Get-IBObject 'record:host' -Filter 'name=web1.example.com'

# Modify the first listed IP address
$myhost.ipv4addrs[0].ipv4addr = '10.10.10.100'

# remove the read-only 'host' field from the nested 'record:host_ipv4addr' object
$myhost.ipv4addrs[0].PSObject.Properties.Remove('host')

# Save the result
$myhost | Set-IBObject
```

If you need to make the same change to a set of objects, you can also pass the set of object references via the pipeline and use a template object to change all of them in the same way.

```powershell
# Get all hosts in the Los Angeles site
$laHosts = Get-IBObject 'record:host' -Filter @{'*Site'='Los Angeles'}

# Move them to the New York site
$laHosts | Set-IBObject -Template @{extattrs=@{Site=@{value='New York'}}}
```

Deleting one or more objects is as simple as passing one or more object references to `Remove-IBObject`.

```powershell
# Get hosts being decommissioned
$toDelete = Get-IBObject 'record:host' -Filter 'comment=decommission'

# Delete them
$toDelete | Remove-IBObject
```

For more examples, check the [Definitive REST Examples](Guides/Definitive-REST-Examples.md) guide.

## Requirements and Platform Support

* Supports Windows PowerShell 5.1 (Desktop edition) with .NET Framework 4.5.2 or later
* Supports [PowerShell](https://github.com/PowerShell/PowerShell) 7.0 or later (Core edition) on all supported OS platforms.
* Supports any NIOS/WAPI version, but only regularly tested against Infoblox supported versions.

## Changelog

See [CHANGELOG.md](https://github.com/rmbolger/Posh-IBWAPI/blob/main/CHANGELOG.md)
