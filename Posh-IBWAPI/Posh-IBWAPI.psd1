@{

RootModule = 'Posh-IBWAPI.psm1'
ModuleVersion = '3.2.0'
GUID = '1483924a-a8bd-446f-ba0a-25443bcec77e'
Author = 'Ryan Bolger'
Copyright = '(c) 2017-2020 Ryan Bolger. All rights reserved.'
Description = 'Infoblox WAPI (REST API) related commands.'
PowerShellVersion = '3.0'

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

        # Tags applied to this module. These help with module discovery in online galleries.
        Tags = 'Infoblox','IPAM','WAPI','REST','PSEdition_Desktop','PSEdition_Core','Linux','Mac'

        # A URL to the license for this module.
        LicenseUri = 'https://github.com/rmbolger/Posh-IBWAPI/blob/main/LICENSE'

        # A URL to the main website for this project.
        ProjectUri = 'https://github.com/rmbolger/Posh-IBWAPI'

        # A URL to an icon representing this module.
        # IconUri = ''

        # ReleaseNotes of this module
        ReleaseNotes = @'
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
'@

    } # End of PSData hashtable

} # End of PrivateData hashtable

}
