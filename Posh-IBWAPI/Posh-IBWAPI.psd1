@{

# Script module or binary module file associated with this manifest.
RootModule = 'Posh-IBWAPI.psm1'

# Version number of this module.
ModuleVersion = '2.0.0'

# Supported PSEditions (WARNING: BREAKS COMPATIBILITY with pre-5.1 Powershell)
# CompatiblePSEditions = 'Desktop','Core'

# ID used to uniquely identify this module
GUID = '1483924a-a8bd-446f-ba0a-25443bcec77e'

# Author of this module
Author = 'Ryan Bolger'

# Company or vendor of this module
#CompanyName = ''

# Copyright statement for this module
Copyright = '(c) 2017-2018 Ryan Bolger. All rights reserved.'

# Description of the functionality provided by this module
Description = 'Infoblox WAPI (REST API) related commands.'

# Minimum version of the Windows PowerShell engine required by this module
PowerShellVersion = '3.0'

# Name of the Windows PowerShell host required by this module
# PowerShellHostName = ''

# Minimum version of the Windows PowerShell host required by this module
# PowerShellHostVersion = ''

# Minimum version of Microsoft .NET Framework required by this module. This prerequisite is valid for the PowerShell Desktop edition only.
# DotNetFrameworkVersion = ''

# Minimum version of the common language runtime (CLR) required by this module. This prerequisite is valid for the PowerShell Desktop edition only.
# CLRVersion = ''

# Processor architecture (None, X86, Amd64) required by this module
# ProcessorArchitecture = ''

# Modules that must be imported into the global environment prior to importing this module
# RequiredModules = @()

# Assemblies that must be loaded prior to importing this module
# RequiredAssemblies = @()

# Script files (.ps1) that are run in the caller's environment prior to importing this module.
# ScriptsToProcess = @()

# Type files (.ps1xml) to be loaded when importing this module
# TypesToProcess = @()

# Format files (.ps1xml) to be loaded when importing this module
FormatsToProcess = 'Posh-IBWAPI.Format.ps1xml'

# Modules to import as nested modules of the module specified in RootModule/ModuleToProcess
# NestedModules = @()

# Functions to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no functions to export.
FunctionsToExport = @(
    'Get-IBConfig',
    'Get-IBObject',
    'Get-IBSchema',
    'Invoke-IBFunction',
    'Invoke-IBWAPI',
    'New-IBObject',
    'Receive-IBFile',
    'Remove-IBConfig',
    'Remove-IBObject',
    'Send-IBFile',
    'Set-IBConfig',
    'Set-IBObject'
)

# Cmdlets to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no cmdlets to export.
CmdletsToExport = @()

# Variables to export from this module
VariablesToExport = @()

# Aliases to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no aliases to export.
AliasesToExport = @()

# DSC resources to export from this module
# DscResourcesToExport = @()

# List of all modules packaged with this module
# ModuleList = @()

# List of all files packaged with this module
# FileList = @()

# Private data to pass to the module specified in RootModule/ModuleToProcess. This may also contain a PSData hashtable with additional module metadata used by PowerShell.
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
'@

    } # End of PSData hashtable

} # End of PrivateData hashtable

# HelpInfo URI of this module
# HelpInfoURI = ''

# Default prefix for commands exported from this module. Override the default prefix using Import-Module -Prefix.
# DefaultCommandPrefix = ''

}
