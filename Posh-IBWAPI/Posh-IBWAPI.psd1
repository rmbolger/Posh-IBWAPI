@{

RootModule = 'Posh-IBWAPI.psm1'
ModuleVersion = '4.1.0'
GUID = '1483924a-a8bd-446f-ba0a-25443bcec77e'
Author = 'Ryan Bolger'
Copyright = '(c) 2017-2022 Ryan Bolger. All rights reserved.'
Description = 'Infoblox WAPI (REST API) related commands.'
CompatiblePSEditions = @('Desktop','Core')
PowerShellVersion = '5.1'
DotNetFrameworkVersion = '4.5.2'

FormatsToProcess = 'Posh-IBWAPI.Format.ps1xml'

FunctionsToExport = @(
    'Get-IBConfig'
    'Get-IBObject'
    'Get-IBSchema'
    'Invoke-IBFunction'
    'Invoke-IBWAPI'
    'New-IBObject'
    'Receive-IBFile'
    'Remove-IBConfig'
    'Remove-IBObject'
    'Send-IBFile'
    'Set-IBConfig'
    'Set-IBObject'
)

CmdletsToExport = @()
VariablesToExport = @()
AliasesToExport = @()

PrivateData = @{

    PSData = @{

        Tags = 'Infoblox','IPAM','WAPI','REST','Linux','Mac'
        LicenseUri = 'https://github.com/rmbolger/Posh-IBWAPI/blob/main/LICENSE'
        ProjectUri = 'https://github.com/rmbolger/Posh-IBWAPI'
        ReleaseNotes = @'
## 4.1.0 (2025-02-06)

* Added `-Inheritance` switch to `Get-IBObject` which requests WAPI to return inherited values for returned fields that support inheritance. This requires WAPI 2.10.2 or later.
  * WARNING: Depending on the field, the structure of the field's data may be different than a non-inheritance request. Be sure to test both ways to understand the differences in your use-case.
* Fixed a problem with BatchMode calls to `Get-IBObject` that wouldn't properly send the `-ProxySearch` flag to batched queries when specified.
* Changed low level URL encoding method to use `[System.Uri]::EscapeDataString()` which removes the explicit dependency on System.Web that was needed in PowerShell 5.1.
'@

    }

}

}
