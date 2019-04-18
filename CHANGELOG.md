## 2.0.0 (2019-04-18)

* Breaking Changes
  * .NET 4.5+ is now required on PowerShell Desktop edition for full functionality. A warning will be thrown when loading the module if it is not found.
  * The `WebSession` parameter has been removed from all functions except `Invoke-IBWAPI`. Session handling is now automatic.
  * `New-IBSession` has been removed.
  * `Get-IBWAPIConfig`, `Set-IBWAPIConfig`, and `Remove-IBWAPIConfig` have been renamed to `Get-IBConfig`, `Set-IBConfig`, and `Remove-IBConfig` respectively.
  * `Save-IBWAPIConfig` has been removed. Configs are now saved by default via `Set-IBConfig`.
  * Configs are now referenced by a `ProfileName`. Old 1.x configs will be automatically backed up, converted, and the new profiles will have their WAPIHost value set as the initial profile name.
  * `Set-IBConfig` now has `ProfileName` as its first parameter.
  * `Get-IBConfig` and `Remove-IBConfig` now have `ProfileName` instead of `WAPIHost` as their selection parameter.
  * The `IgnoreCertificateValidation` switch has been renamed to `SkipCertificateCheck` in all functions and configs to be more in line with PowerShell Core.
  * The `ObjectRef` parameter in `Invoke-IBFunction` has been changed to `ObjectType` which is functionally how it always worked and was inappropriately named. Functions get called against object types not references.
* New Feature: Automatic session handling. The module will now automatically save and use WebSession objects to increase authentication efficiency over multiple requests and function calls.
* New Feature: Named configuration profiles. This will allow you to save multiple profiles for the same WAPI host with different credentials, WAPI versions, etc.
* New functions `Send-IBFile` and `Recieve-IBFile` which are convenient wrappers around the fileop functions. See the cmdlet help or the guide in the wiki for more details.
* Config profiles are now automatically saved to disk when using `Set-IBConfig`.
* `Set-IBConfig` now has a `NewName` parameter to rename the profile.
* `Get-IBConfig` now returns a typed object with a automatically styled display.
* `Remove-IBConfig` now has pipeline support both by value and property name so you can pipe the output of `Get-IBConfig` to it.
* `Get-IBConfig`, `Set-IBConfig`, and `Remove-IBConfig` now have tab completion on PowerShell 5.0 or later.

## 1.6.0 (2019-04-04)

* Added -NoPaging switch in Get-IBObject (#34) (Thanks @basvinken)

## 1.5.0 (2018-09-28)

* Added ByType as default parameter set for `Get-IBObject` which means you can query types like this `Get-IBObject grid` instead of needing the explicit `-ObjectType` parameter name.
* Get/Set/New/Remove-IBObject and Invoke-IBFunction were failing to properly process direct `-ObjectRef` input arrays. The parameter has been changed to a single string and if you want them to process multiple, you must use pipeline input now.
* Fixed bug failing to load saved config on some versions of PowerShell
* Fixed HTTP 400/BadRequest error handling when running on PowerShell Core
* Minor code refactoring to align with PSScriptAnalyzer suggestions

## 1.4.0 (2018-04-26)
* Added `-PageSize` parameter to `Get-IBObject` to work around large responses causing JSON deserialization errors as in issue #26

## 1.3.0 (2018-01-25)
* Persistent config support
  * New `Save-IBWAPIConfig` and `Remove-IBWAPIConfig` functions
  * `posh-ibwapi.json` stored `%LOCALAPPDATA%` on Windows, `~/.config` on Linux, and `~/Library/Preferences` on MacOS
  * Passwords encrypted using `ConvertFrom-SecureString` on Windows, but only Base64 on non-Windows until PowerShell team fixes compatibility
* Switching to a new config set with `Set-IBWAPIConfig` no longer copies the settings from the old config if they weren't specified. This was never really documented and was causing confusion more than helping.

## 1.2.2 (2018-01-13)
* [Powershell Core](https://github.com/PowerShell/PowerShell) support!

## 1.2.1 (2018-01-09)
* Added Grid Master Candidate meta refresh detection. So if your grid master candidates are configured to redirect to the current grid master, the module will automatically re-try the query there and throw a warning, rather than failing with an error.
* Fixed a potential null reference exception
* Misc code refactoring

## 1.2.0 (2017-09-30)
* Added Get-IBSchema for Get-Help style querying of the WAPI object model. *(Requires WAPI 1.7.5+)*
* Added -ReturnAllFields parameter to Get-IBObject which will return all possible fields for an object without needing to explicitly specify each one. *(Requires WAPI 1.7.5+)*
* Fixed credential checking in Initialize-CallVars
* Fixed empty results throwing an error in Get-IBObject

## 1.1.2 (2017-09-04)
* Tweaked Get-IBObject paging so that MaxResults will limit page size if smaller than default, thus not requesting more data than necessary
* Fix for issue #17. JSON bodies are now explicitly UTF8 encoded to prevent issues with non-ASCII characters

## 1.1.1 (2017-05-26)
* Fix for issue #16 (regression bug with Set-IBWAPIConfig and -IgnoreCertificateValidation)

## 1.1.0 (2017-05-26)
* Multi-Host config support
  * Set-IBWAPIConfig now supports saving values per-WAPIHost
  * Switch the 'active' host by calling Set-IBWAPIConfig with just the -WAPIHost parameter
  * Use -NoSwitchHost to update config values for a host without switching the 'active' host
* Added -DeleteArgs to Remove-IBObject for issue #11
* Fix for issue #15 regarding errors when TLS 1.0 is disabled in Infoblox
* Misc internal refactoring

## 1.0.1 (2017-04-26)

* Readme tweaks
* Potential fix for issue #10 regarding 401 errors with Set-IBWAPIConfig -ver latest

## 1.0.0 (2017-04-20)

* Initial Release
* Added functions
  * Get-IBObject
  * Get-IBWAPIConfig
  * Invoke-IBFunction
  * Invoke-IBWAPI
  * New-IBObject
  * New-IBWAPISession
  * Remove-IBObject
  * Set-IBObject
  * Set-IBWAPIConfig
