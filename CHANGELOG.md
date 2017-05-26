## 1.1.1 (2017-05-26)
* Fix for issue #16 (regression bug with Set-IBWAPIConfig and -IgnoreCertificateValidation

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
