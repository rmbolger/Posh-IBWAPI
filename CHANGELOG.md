## 3.2.2 (2022-03-17)

* Added ObjectType argument completer for Get-IBObject, New-IBObject, and Get-IBSchema. Currently requires having already run Get-IBSchema to cache the potential values.
* Fixed issue propagating SkipCertificateCheck switch in api calls during `Send-IBFile` and `Receive-IBFile`

## 3.2.1 (2021-08-02)

* Added additional examples on `New-IBObject` and `Get-IBObject` (Thanks @qlikq)
* Fixed `Send-IBFile` throwing a PropertyNotFound exception when no FunctionArgs are specified. (#55) (Thanks @demdante)
* Fixed `Remove-IBConfig -All` not working
* Corrupt or unparseable config files are now handled more gracefully.
* Added a warning when importing a config on Linux/Mac that was originally created on Windows
* `Export-IBConfig` no longer writes an output file if no profiles are defined.

## 3.2.0 (2020-09-21)

* An optional `ProfileName` parameter has been added to the public functions that already accept connection specific parameters (#49). This will allow you to switch profiles on a per-call basis more easily. The connection specific parameters will still override the a specified profile's values. These are the affected functions:
  * Get-IBObject
  * Get-IBSchema
  * Invoke-IBFunction
  * New-IBObject
  * Receive-IBFile
  * Remove-IBObject
  * Send-IBFile
  * Set-IBObject
* `ProfileName` is now a positional parameter in `Remove-IBConfig`
* Minor efficiency improvements in `Get-IBObject` for results with many pages.
* The name of the default branch in git has been renamed from master to main.

## 3.1.2 (2020-04-15)

* Fixed bug with Remove-IBObject that would inherit invalid return field parameters in some cases.

## 3.1.1 (2020-03-10)

* Better error handling in Set-IBConfig when ProfileName not specified and no active profile selected. (#47)
* Fixed dev install script for redirected docs locations

## 3.1.0 (2019-08-23)

* Added `OverrideTransferHost` switch to `Send-IBFile` and `Receive-IBFile` which tweaks the WAPI supplied transfer URL so that the hostname matches the WAPIHost value originally passed to the function. It also copies the state of the `SkipCertificate` switch to the transfer call.
* `Send-IBFile` will no longer lock the file being uploaded so other readers can't read it.
* Fixed file encoding in `Send-IBFile` when uploading non-ascii files.
* Fixed `Receive-IBFile` on PowerShell Core by working around an upstream bug (#43)
* Fixed `Get-IBObject`'s `ReturnAllFields` parameter when not querying the latest WAPI version

## 3.0.0 (2019-04-20)

* Breaking Changes
  * The change to `ObjectType` parameter in `Invoke-IBFunction` has been reverted to `ObjectRef` like in 1.x. I totally confused myself during 2.x development of the *-IBFile functions and thought it had been wrong the whole time. It seems silly to do another major version change after two days. But breaking changes demand it according to semver.
  * The `ObjectType` parameter in `Send-IBFile` and `Receive-IBFile` have been changed to `ObjectRef` to match `Invoke-IBFunction`. Both still default to 'fileop' and have parameter aliases for 'type' and 'ObjectType' to maintain compatibility with the short lived 2.x codebase.
* Fixed example in `Invoke-IBFunction` help.

## 2.0.1 (2019-04-19)

* Fixed `Send-IBFile` for PowerShell 3/4

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
