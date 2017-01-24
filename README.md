# Description

This PowerShell module makes it easier to automate Infoblox WAPI requests and functions. It is not intended to wrap every object into a set of custom cmdlets. Instead, it aims to hide some of the tedious complexity in calling a REST API via PowerShell.

# Install

To install the latest development version from git, use the following command in PowerShell v3 or later:

```
iex (invoke-restmethod https://raw.githubusercontent.com/rmbolger/Posh-IBWAPI/master/instdev.ps1)
```

You can also find the [latest release](https://www.powershellgallery.com/packages/Posh-IBWAPI) version in the PowerShell Gallery. If you're on PowerShell v5 or later, you can install it with `Install-Module`.

```
Install-Module -Name Posh-IBWAPI
```

# Support

* Requires PowerShell v3 or later.
* Tested against NIOS 7.3.x.

# Changelog

See [CHANGELOG.md](/CHANGELOG.md)