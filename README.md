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

Every WAPI call needs a host, version, and credentials. Set them once for the session with `Set-IBWAPIConfig` and you won't need to add them to every call. If your grid is still using self-signed certs, you may also need to use the `-IgnoreCertificateValidate` parameter. The `-WAPIVersion` parameter also accepts `'latest'` and will query the grid master for the latest supported version.

    Set-IBWAPIConfig -host gridmaster.example.com -version latest -cred (Get-Credential) -IgnoreCert $True

Retrieve a set of objects using `Get-IBObject`. The only required parameter is `-ObjectType`. Everything else like filters and return fields are optional.

    Get-IBObject -type record:host
    Get-IBObject -type record:host -Filters "name~=example.com" -Max 10 -fields extattrs

You may notice that all objects returned by Infoblox have a `_ref` field. That is known as the object reference and can be used in any function that accepts `-ObjectRef`. In the case of `Get-IBObject`, it will return that specific object.

    Get-IBObject -ref 'record:host/asdfqwerasdfqwerasdfqwerasdfqwer'

Create a new object with `New-IBObject`. All you need to provide is the object type and an object with the minimum required fields defined. Embedded WAPI functions work just fine here.

    # Build the record:host object we want to create.
    # NOTE: An error will be thrown if the example.com DNS zone doesn't
    # exist in Infoblox
    $newhost = @{name='web1.example.com';comment='web server'}
    $newhost.ipv4addrs = @( @{ipv4addr='10.10.10.1'} )

    # Create the object
    New-IBObject -type record:host -IBObject $newhost

    # Modify the object so we can make another and this time use an
    # embedded function to set the IP address.
    $newhost.name = 'web2.example.com'
    $newhost.ipv4addrs = @( @{ipv4addr='func:nextavailableip:10.10.10.0/24'} )
    New-IBObject -type record:host -IBObject $newhost

To modify an object, the easiest way is usually to get a copy of it, modify the copy, and save the result with `Set-IBObject`. *Be wary of objects that return read-only fields. You need to strip them out before saving or an error will be thrown.*

    # Get a copy of the host
    $myhost = Get-IBObject -type record:host -Filters 'name=web1.example.com'

    # Modify the first listed IP address
    $myhost.ipv4addrs[0] = @{ ipv4addr='10.10.10.100' }

    # Save the result
    $myhost | Set-IBObject

If you need to make the same change to a set of objects, you can also pass the set of object references via the pipeline and use a template object to change all of them in the same way.

    # Get all hosts in the Los Angeles site
    $laHosts = Get-IBObject -type record:host -Filters '*Site=Los Angeles'

    # Move them to the New York site
    $laHosts | Set-IBObject -Template @{extattrs=@{Site=@{value='New York'}}}


Deleting one or more objects is as simple as passing one or more object references to `Remove-IBObject`.

    # Get hosts being decommissioned
    $toDelete = Get-IBObject -type record:host -Filters 'comment=decommission'

    # Delete them
    $toDelete | Remove-IBObject


# Requirements and Platform Support

* Requires PowerShell v3 or later.
* Tested against NIOS 7.3.x and 8.x.

# Changelog

See [CHANGELOG.md](/CHANGELOG.md)