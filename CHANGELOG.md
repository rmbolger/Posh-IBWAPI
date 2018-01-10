## 1.2.1 (2018-01-09)
* Added Grid Master Candidate meta refresh detection. So if your grid master candidates are configured to redirect to the current grid master, the module will automatically re-try the query there and throw a warning, rather than failing with an error.
* Fixed a potential null reference exception
* Misc code refactoring

## 1.2 (2017-09-30)
* Added Get-IBSchema for Get-Help style querying of the WAPI object model. *(Requires WAPI 1.7.5+)*
* Added -ReturnAllFields parameter to Get-IBObject which will return all possible fields for an object without needing to explicitly specify each one. *(Requires WAPI 1.7.5+)*
* Fixed credential checking in Initialize-CallVars
* Fixed empty results throwing an error in Get-IBObject

## 1.1.2 (2017-09-04)
* Tweaked Get-IBObject paging so that MaxResults will limit page size if smaller than default, thus not requesting more data than necessary
* Fix for issue #17. JSON bodies are now explicitly UTF8 encoded to prevent issues with non-ASCII characters

## 1.1.1 (2017-05-26)
* Fix for issue #16 (regression bug with Set-IBWAPIConfig and -IgnoreCertificateValidation)

## 1.1 (2017-05-26)
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

## 1.0 (2017-04-20)

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
