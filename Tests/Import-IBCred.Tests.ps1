Describe "Import-IBCred" {

    BeforeAll {
        $env:LOCALAPPDATA = 'TestDrive:\'
        $env:HOME = 'TestDrive:\'
        Import-Module (Join-Path $PSScriptRoot '..\Posh-IBWAPI\Posh-IBWAPI.psd1')

        Mock Write-Warning -ModuleName Posh-IBWAPI {}
    }

    It "Processes a valid SecureString credential" {
        InModuleScope Posh-IBWAPI {

            $test = [pscustomobject]@{
                Username = 'admin1'
                Password = ConvertTo-SecureString 'password1' -AsPlainText -Force |
                    ConvertFrom-SecureString
            }

            { Import-IBCred $test 'prof1' } | Should -Not -Throw

            $cred = Import-IBCred $test 'prof1'
            if ($IsLinux -or $IsMacOS) {
                Should -Invoke Write-Warning -ModuleName Posh-IBWAPI
            } else {
                Should -Not -Invoke Write-Warning -ModuleName Posh-IBWAPI
            }

            $cred = Import-IBCred $test 'prof1'
            $cred | Should -BeOfType System.Management.Automation.PSCredential
            $cred.Username | Should -Be 'admin1'
            $cred.GetNetworkCredential().Password | Should -Be 'password1'
        }
    }

    It "Processes a valid Base64 credential" {
        InModuleScope Posh-IBWAPI {

            $test = [pscustomobject]@{
                Username = 'admin1'
                Password = [Convert]::ToBase64String(
                    [Text.Encoding]::Unicode.GetBytes('password1')
                )
                IsBase64 = $true
            }

            { Import-IBCred $test 'prof1' } | Should -Not -Throw

            $cred = Import-IBCred $test 'prof1'
            Should -Not -Invoke Write-Warning -ModuleName Posh-IBWAPI

            $cred | Should -BeOfType System.Management.Automation.PSCredential
            $cred.Username | Should -Be 'admin1'
            $cred.GetNetworkCredential().Password | Should -Be 'password1'
        }
    }

    It "Warns on invalid SecureString credential" {
        InModuleScope Posh-IBWAPI {

            $test = [pscustomobject]@{
                Username = 'admin1'
                # securestring from another system that shouldn't be decryptable
                Password = '01000000d08c9ddf0115d1118c7a00c04fc297eb01000000db862613967e8545bdc54dc3986004320000000002000000000003660000c000000010000000ea20f11c46de07d98d335f8eff6516bc0000000004800000a000000010000000635d2c3e7b4351dea0d2b13452b07fa418000000369f7b500285c23927ab0bf01e90d2b6875661f9547d51661400000069c7d9e9b2a13e64ead95469643f893a02797265'
            }

            { Import-IBCred $test 'prof1' } | Should -Not -Throw

            $cred = Import-IBCred $test 'prof1'
            Should -Invoke Write-Warning -ModuleName Posh-IBWAPI

            if ($IsLinux -or $IsMacOS) {
                # non-Windows will succeed blindly parsing the securestring
                # even though it's invalid
                $cred | Should -Not -BeNullOrEmpty
            } else {
                $cred | Should -BeNullOrEmpty
            }
        }
    }

    It "Warns on invalid Base64 credential" {
        InModuleScope Posh-IBWAPI {

            $test = [pscustomobject]@{
                Username = 'admin1'
                # bad Base64 value
                Password = 'cABhAHMAcwB3AG8AcgBkADEA='
            }

            { Import-IBCred $test 'prof1' } | Should -Not -Throw

            Import-IBCred $test 'prof1' | Should -BeNullOrEmpty
            Should -Invoke Write-Warning -ModuleName Posh-IBWAPI
        }
    }
}
