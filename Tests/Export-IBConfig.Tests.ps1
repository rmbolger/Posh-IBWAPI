Describe "Export-IBConfig" {

    BeforeAll {
        $env:LOCALAPPDATA = 'TestDrive:\'
        $env:HOME = 'TestDrive:\'
        $env:IBWAPI_VAULT_NAME = $null
        $env:IBWAPI_VAULT_PASS = $null
        $env:IBWAPI_VAULT_SECRET_TEMPLATE = $null
        Import-Module (Join-Path $PSScriptRoot '..\Posh-IBWAPI\Posh-IBWAPI.psd1')

        # setup fake profile export location
        $fakeConfigFolder = 'TestDrive:\config'
        $fakeConfigFile   = 'TestDrive:\config\posh-ibwapi.json'

        # setup fake profiles for mocking with
        $fakePass1 = ConvertTo-SecureString 'password1' -AsPlainText -Force
        $fakeCred1 = [pscredential]::new('admin1',$fakePass1)
        $prof1 = @{
            WAPIHost = 'gm1'
            WAPIVersion = '1.0'
            Credential = $fakeCred1
            SkipCertificateCheck = $false
            NoSession = $true
        }

        $fakePass2 = ConvertTo-SecureString 'password2' -AsPlainText -Force
        $fakeCred2 = New-Object PSCredential 'admin2',$fakePass2
        $prof2 = @{
            WAPIHost = 'gm2'
            WAPIVersion = '2.0'
            Credential = $fakeCred2
            SkipCertificateCheck = $true
            NoSession = $false
        }

        $fakeVaultConfig = @{
            Name = 'vault1'
            Template = 'poshibwapi-{0}'
        }
        $fakeVaultProfile1 = @{
            WAPIHost = 'gm1'
            WAPIVersion = '1.0'
            Credential = @{
                Username = 'admin1'
                Password = 'password1'
            }
            SkipCertificateCheck = $false
            NoSession = $true
            Current = $true
        }
        $fakeVaultProfile2 = @{
            WAPIHost = 'gm2'
            WAPIVersion = '2.0'
            Credential = @{
                Username = 'admin2'
                Password = 'password2'
            }
            SkipCertificateCheck = $true
            NoSession = $false
            Current = $false
        }
    }

    Context "No profiles" {

        BeforeAll {
            Mock -ModuleName Posh-IBWAPI Get-ConfigFolder { $fakeConfigFolder }
            Mock -ModuleName Posh-IBWAPI Get-ConfigFile { $fakeConfigFile }
            Mock -ModuleName Posh-IBWAPI Get-Profiles { return @{} }
            Mock -ModuleName Posh-IBWAPI Get-CurrentProfile { return [string]::Empty }
        }

        It "Saves nothing (local)" {
            InModuleScope Posh-IBWAPI {

                Import-IBConfig
                Export-IBConfig

                Get-ConfigFile | Should -Not -Exist
            }
        }

        It "Saves nothing (vault)" {

            Mock -ModuleName Posh-IBWAPI Get-VaultConfig { $fakeVaultConfig }
            Mock -ModuleName Posh-IBWAPI Get-VaultProfiles { }
            Mock -ModuleName Posh-IBWAPI Set-Secret { }
            Mock -ModuleName Posh-IBWAPI Remove-Secret { }

            InModuleScope Posh-IBWAPI {

                Import-IBConfig
                Export-IBConfig

                Get-ConfigFile | Should -Not -Exist
                Should -Not -Invoke Set-Secret
                Should -Not -Invoke Remove-Secret
            }
        }
    }

    Context "1 active profile" {

        BeforeAll {
            Mock -ModuleName Posh-IBWAPI Get-ConfigFolder { $fakeConfigFolder }
            Mock -ModuleName Posh-IBWAPI Get-ConfigFile { $fakeConfigFile }
            Mock -ModuleName Posh-IBWAPI Get-Profiles { return @{ 'prof1' = $prof1 } }
            Mock -ModuleName Posh-IBWAPI Get-CurrentProfile { return 'prof1' }
        }

        It "Saves the profile (local)" {
            InModuleScope Posh-IBWAPI {

                Import-IBConfig
                Export-IBConfig

                Get-ConfigFile | Should -Exist

                $json = Get-Content (Get-ConfigFile) -Raw | ConvertFrom-Json

                $json.CurrentProfile   | Should -Be 'prof1'
                $json.Profiles.'prof1' | Should -Not -BeNullOrEmpty

                $prof = $json.Profiles.'prof1'

                $prof.WAPIHost    | Should -Be 'gm1'
                $prof.WAPIVersion | Should -Be '1.0'
                $prof.SkipCertificateCheck | Should -BeFalse
                $prof.NoSession | Should -BeTrue
                $prof.Credential.Username | Should -Be 'admin1'
                if ($IsWindows -or (-not $PSEdition) -or $PSEdition -eq 'Desktop') {
                    $secPass = $prof.Credential.Password | ConvertTo-SecureString
                    $testPass = (New-Object PSCredential 'test',$secPass).GetNetworkCredential().Password
                    $testPass | Should -Be 'password1'
                } else {
                    $prof.Credential.IsBase64 | Should -BeTrue
                    $testVal = [Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes('password1'))
                    $prof.Credential.Password | Should -Be $testVal
                }

                # cleanup
                Remove-Item (Get-ConfigFile)
            }
        }

        It "Saves a new profile (vault)" {
            Mock -ModuleName Posh-IBWAPI Get-VaultConfig { $fakeVaultConfig }
            Mock -ModuleName Posh-IBWAPI Get-VaultProfiles { }

            InModuleScope Posh-IBWAPI {
                Mock Remove-Secret { }
                Mock Set-Secret { }

                Import-IBConfig
                Export-IBConfig

                Get-ConfigFile | Should -Not -Exist

                Should -Invoke Set-Secret -ParameterFilter {
                    $Vault -eq 'vault1' -and $Name -eq 'poshibwapi-prof1'
                }
                Should -Not -Invoke Remove-Secret
            }
        }

        It "Saves a renamed profile (vault)" {
            Mock -ModuleName Posh-IBWAPI Get-VaultConfig { $fakeVaultConfig }
            Mock -ModuleName Posh-IBWAPI Get-VaultProfiles { return @{ 'oldprof1' = $fakeVaultProfile1 }}

            InModuleScope Posh-IBWAPI {
                Mock Remove-Secret { }
                Mock Set-Secret { }

                Import-IBConfig
                Export-IBConfig

                Get-ConfigFile | Should -Not -Exist

                Should -Invoke Set-Secret -ParameterFilter {
                    $Vault -eq 'vault1' -and $Name -eq 'poshibwapi-prof1'
                }
                Should -Invoke Remove-Secret -ParameterFilter {
                    $Vault -eq 'vault1' -and $Name -eq 'poshibwapi-oldprof1'
                }
            }
        }

        It "Saves an updated profile (vault)" {
            Mock -ModuleName Posh-IBWAPI Get-VaultConfig { $fakeVaultConfig }
            Mock -ModuleName Posh-IBWAPI Get-VaultProfiles { return @{ 'prof1' = $fakeVaultProfile2 }}

            InModuleScope Posh-IBWAPI {
                Mock Remove-Secret { }
                Mock Set-Secret { }

                Import-IBConfig
                Export-IBConfig

                Get-ConfigFile | Should -Not -Exist

                Should -Invoke Set-Secret -ParameterFilter {
                    $Vault -eq 'vault1' -and $Name -eq 'poshibwapi-prof1'
                }
                Should -Not -Invoke Remove-Secret
            }
        }

        It "Does not save an unchanged profile (vault)" {
            Mock -ModuleName Posh-IBWAPI Get-VaultConfig { $fakeVaultConfig }
            Mock -ModuleName Posh-IBWAPI Get-VaultProfiles { return @{ 'prof1' = $fakeVaultProfile1 }}

            InModuleScope Posh-IBWAPI {
                Mock Remove-Secret { }
                Mock Set-Secret { }

                Import-IBConfig
                Export-IBConfig

                Get-ConfigFile | Should -Not -Exist

                Should -Not -Invoke Set-Secret
                Should -Not -Invoke Remove-Secret
            }
        }
    }

    Context "1 inactive profile" {

        BeforeAll {
            Mock -ModuleName Posh-IBWAPI Get-ConfigFolder { $fakeConfigFolder }
            Mock -ModuleName Posh-IBWAPI Get-ConfigFile { $fakeConfigFile }
            Mock -ModuleName Posh-IBWAPI Get-Profiles { return @{ 'prof1' = $prof1 } }
            Mock -ModuleName Posh-IBWAPI Get-CurrentProfile { return [string]::Empty }
        }

        It "Saves the profile (local)" {
            InModuleScope Posh-IBWAPI {

                Import-IBConfig
                Export-IBConfig

                Get-ConfigFile | Should -Exist

                $json = Get-Content (Get-ConfigFile) -Raw | ConvertFrom-Json

                $json.CurrentProfile   | Should -Be ''
                $json.Profiles.'prof1' | Should -Not -BeNullOrEmpty

                $prof = $json.Profiles.'prof1'

                $prof.WAPIHost    | Should -Be 'gm1'
                $prof.WAPIVersion | Should -Be '1.0'
                $prof.SkipCertificateCheck | Should -BeFalse
                $prof.NoSession | Should -BeTrue
                $prof.Credential.Username | Should -Be 'admin1'
                if ($IsWindows -or (-not $PSEdition) -or $PSEdition -eq 'Desktop') {
                    $secPass = $prof.Credential.Password | ConvertTo-SecureString
                    $testPass = (New-Object PSCredential 'test',$secPass).GetNetworkCredential().Password
                    $testPass | Should -Be 'password1'
                } else {
                    $prof.Credential.IsBase64 | Should -BeTrue
                    $testVal = [Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes('password1'))
                    $prof.Credential.Password | Should -Be $testVal
                }

                # cleanup
                Remove-Item (Get-ConfigFile)
            }
        }

        It "Saves the profile (vault)" {
            Mock -ModuleName Posh-IBWAPI Get-VaultConfig { $fakeVaultConfig }
            Mock -ModuleName Posh-IBWAPI Get-VaultProfiles { }

            InModuleScope Posh-IBWAPI {
                Mock Remove-Secret { }
                Mock Set-Secret { }

                Import-IBConfig
                Export-IBConfig

                Get-ConfigFile | Should -Not -Exist

                Should -Invoke Set-Secret -ParameterFilter {
                    $Vault -eq 'vault1' -and $Name -eq 'poshibwapi-prof1' -and
                    $Secret -like '*"WAPIHost":"gm1"*' -and
                    $Secret -like '*"Current":false*'
                }
                Should -Not -Invoke Remove-Secret
            }

        }

    }

    Context "Multiple profiles with 1 active" {

        BeforeAll {
            Mock -ModuleName Posh-IBWAPI Get-Profiles { return @{
                'prof1' = $prof1
                'prof2' = $prof2
            } }
            Mock -ModuleName Posh-IBWAPI Get-CurrentProfile { return 'prof1' }
        }

        It "Saves the profiles" {
            InModuleScope Posh-IBWAPI {

                Import-IBConfig
                Export-IBConfig

                Get-ConfigFile | Should -Exist

                $json = Get-Content (Get-ConfigFile) -Raw | ConvertFrom-Json

                $json.CurrentProfile   | Should -Be 'prof1'
                $json.Profiles.'prof1' | Should -Not -BeNullOrEmpty
                $json.Profiles.'prof2' | Should -Not -BeNullOrEmpty

                $prof1 = $json.Profiles.'prof1'

                $prof1.WAPIHost    | Should -Be 'gm1'
                $prof1.WAPIVersion | Should -Be '1.0'
                $prof1.SkipCertificateCheck | Should -BeFalse
                $prof1.NoSession | Should -BeTrue
                $prof1.Credential.Username | Should -Be 'admin1'
                if ($IsWindows -or (-not $PSEdition) -or $PSEdition -eq 'Desktop') {
                    $secPass = $prof1.Credential.Password | ConvertTo-SecureString
                    $testPass = (New-Object PSCredential 'test',$secPass).GetNetworkCredential().Password
                    $testPass | Should -Be 'password1'
                } else {
                    $prof1.Credential.IsBase64 | Should -BeTrue
                    $testVal = [Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes('password1'))
                    $prof1.Credential.Password | Should -Be $testVal
                }

                $prof2 = $json.Profiles.'prof2'

                $prof2.WAPIHost    | Should -Be 'gm2'
                $prof2.WAPIVersion | Should -Be '2.0'
                $prof2.SkipCertificateCheck | Should -BeTrue
                $prof2.NoSession | Should -BeFalse
                $prof2.Credential.Username | Should -Be 'admin2'
                if ($IsWindows -or (-not $PSEdition) -or $PSEdition -eq 'Desktop') {
                    $secPass = $prof2.Credential.Password | ConvertTo-SecureString
                    $testPass = (New-Object PSCredential 'test',$secPass).GetNetworkCredential().Password
                    $testPass | Should -Be 'password2'
                } else {
                    $prof2.Credential.IsBase64 | Should -BeTrue
                    $testVal = [Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes('password2'))
                    $prof2.Credential.Password | Should -Be $testVal
                }

            }
        }
    }


}
