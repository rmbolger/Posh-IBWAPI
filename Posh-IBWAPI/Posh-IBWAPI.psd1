@{

RootModule = 'Posh-IBWAPI.psm1'
ModuleVersion = '4.0.2'
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
## 4.0.2 (2024-01-24)

* Fixed url encoding for boolean values in Get-IBObject filters passed by hashtable
'@

    }

}

}
