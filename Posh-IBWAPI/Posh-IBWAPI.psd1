@{

RootModule = 'Posh-IBWAPI.psm1'
ModuleVersion = '4.2.0'
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
## 4.2.0 (2025-07-09)

* Added the option to disable session re-use via the `-NoSession` switch on config profiles and individual public functions. This can negatively affect performance and increase audit log verbosity for large numbers of WAPI calls but is useful in certain edge cases.
  * When used with `Set-IBConfig` all subsequent function calls using that profile will no longer create or save sessions with the WAPI host. Use `-NoSession:$false` to unset.
  * When a profile has sessions enabled, you can still disable session re-use on a per-call basis by adding the `-NoSession` switch to the function you're using.
  * Per-call functions include Get/New/Remove/Set-IBObject, Get-IBSchema, Invoke-IBFunction/IBWAPI, and Receive/Send-IBFile.
'@

    }

}

}
