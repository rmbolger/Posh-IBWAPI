# Frequently Asked Questions (FAQ)

## Does Posh-IBWAPI work cross platform on Powershell (Core)?

YES! The current minimum supported version of PowerShell (Core) is 7.0. Things may still work on 6.x, but I'm not actively testing against it anymore. All OS platforms supported by PowerShell are supported by the module.

## The underlying connection was closed: Cloud not establish trust relationship for the SSL/TLS secure channel.

Your Infoblox is either still using a self-signed SSL certificate or the custom certificate it's using is no longer valid. You can ignore certificate validation using the `-SkipCertificateCheck` parameter on most functions or set it in your connection profile using `Set-IBConfig`.

## Invoke-RestMethod: SSL connect error

Your Infoblox is either still using a self-signed SSL certificate or the custom certificate it's using is no longer valid. You can ignore certificate validation using the `-SkipCertificateCheck` parameter on most functions or set it in your connection profile using `Set-IBConfig`.

## ConvertTo-Json doesn't seem to be converting all nested objects

There's a `-Depth` parameter that "specifies how many levels of contained objects are included in the JSON representation". The default is 2 which is insufficient for some Infoblox objects. I usually set it to 5 just to be safe.

## -SkipCertificateCheck not working consistently when used in the same session as VMware PowerCLI

In legacy Windows PowerShell 5.1, there is unfortunately no native support in `Invoke-RestMethod` (or any related cmdlet) for per-call disabling of certificate validation. Validation logic is controlled globally at the .NET level on a per-session basis in [System.Net.ServicePointManager](https://msdn.microsoft.com/en-us/library/system.net.servicepointmanager(v=vs.110).aspx). In order to mimic a per-call disable flag, we're essentially disabling cert validation globally just long enough to make our call to `Invoke-RestMethod` and then setting it back to the default functionality.  But our ServicePointManager tweaks seem to sometimes conflict with whatever VMware is doing with PowerCLI to disable certificate validation.

The current recommendation is to just let PowerCLI take care of disabling validation and skip using the option in Posh-IBWAPI. Switching to PowerShell 7+ will also avoid the problem because there *is* per-call disabling of certificate validation.

## Key not valid for use in specified state

This happens when you try to copy a `posh-ibwapi.json` config file to a different Windows computer or a different user's profile on the same computer. The underlying APIs used to encrypt the password in the file are tied to both the current computer and user and are not portable. The rest of the config values should still be valid. You will just need to set new `-Credential` value with `Set-IBConfig`.

Using a centralized [SecretManagement](https://devblogs.microsoft.com/powershell/secretmanagement-and-secretstore-are-generally-available/) vault is also another alternative to share profiles across users or computers.
