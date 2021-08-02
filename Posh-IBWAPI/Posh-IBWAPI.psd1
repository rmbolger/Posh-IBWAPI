@{

RootModule = 'Posh-IBWAPI.psm1'
ModuleVersion = '3.2.1'
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
## 3.2.1 (2021-08-02)

* Added additional examples on `New-IBObject` and `Get-IBObject` (Thanks @qlikq)
* Fixed `Send-IBFile` throwing a PropertyNotFound exception when no FunctionArgs are specified. (#55) (Thanks @demdante)
* Fixed `Remove-IBConfig -All` not working
* Corrupt or unparseable config files are now handled more gracefully.
* Added a warning when importing a config on Linux/Mac that was originally created on Windows
* `Export-IBConfig` no longer writes an output file if no profiles are defined.
'@

    } # End of PSData hashtable

} # End of PrivateData hashtable

}
