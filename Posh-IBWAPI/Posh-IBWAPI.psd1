@{

RootModule = 'Posh-IBWAPI.psm1'
ModuleVersion = '3.1.0'
GUID = '1483924a-a8bd-446f-ba0a-25443bcec77e'
Author = 'Ryan Bolger'
Copyright = '(c) 2017-2019 Ryan Bolger. All rights reserved.'
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
        LicenseUri = 'https://github.com/rmbolger/Posh-IBWAPI/blob/master/LICENSE'

        # A URL to the main website for this project.
        ProjectUri = 'https://github.com/rmbolger/Posh-IBWAPI'

        # A URL to an icon representing this module.
        # IconUri = ''

        # ReleaseNotes of this module
        ReleaseNotes = @'
## 3.1.0 (2019-08-23)

* Added `OverrideTransferHost` switch to `Send-IBFile` and `Receive-IBFile` which tweaks the WAPI supplied transfer URL so that the hostname matches the WAPIHost value originally passed to the function. It also copies the state of the `SkipCertificate` switch to the transfer call.
* `Send-IBFile` will no longer lock the file being uploaded so other readers can't read it.
* Fixed file encoding in `Send-IBFile` when uploading non-ascii files.
* Fixed `Receive-IBFile` on PowerShell Core by working around an upstream bug (#43)
* Fixed `Get-IBObject`'s `ReturnAllFields` parameter when not querying the latest WAPI version
'@

    } # End of PSData hashtable

} # End of PrivateData hashtable

}
