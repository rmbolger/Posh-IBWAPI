# Description

This PowerShell module makes it easier to automate Infoblox WAPI requests and functions. It is not intended to wrap every object into a set of custom cmdlets or strong types. Instead, it aims to hide some of the tedious complexity in calling the Infoblox REST API via PowerShell.

# Notable Features

- Automatic paging for large GET result sets
- Error details in the body of HTTP 400 responses are exposed instead of being swallowed by Invoke-RestMethod.
- Pipeline support so you can do things like get a set of objects to delete and pipe that set to the Remove-IBObject function.
- Optionally ignore certificate validation errors.
- Save common connection parameters on a per-session basis so you don't need to pass them to every function call.

# Install

To install the latest development version from git, use the following command in PowerShell v3 or later:

```powershell
iex (invoke-restmethod https://raw.githubusercontent.com/rmbolger/Posh-IBWAPI/master/instdev.ps1)
```

You can also find the [latest release](https://www.powershellgallery.com/packages/Posh-IBWAPI) version in the PowerShell Gallery. If you're on PowerShell v5 or later, you can install it with `Install-Module`.

```powershell
Install-Module -Name Posh-IBWAPI
```

# Quick Start

TODO

# Requirements and Platform Support

* Requires PowerShell v3 or later.
* Tested against NIOS 7.3.x and 8.x.

# Changelog

See [CHANGELOG.md](/CHANGELOG.md)