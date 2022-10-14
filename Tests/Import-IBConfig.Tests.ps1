Describe "Import-IBConfig" {

    BeforeAll {
        $env:LOCALAPPDATA = 'TestDrive:\'
        $env:HOME = 'TestDrive:\'
        $env:IBWAPI_HOST = $null
        $env:IBWAPI_VERSION = $null
        $env:IBWAPI_USERNAME = $null
        $env:IBWAPI_PASSWORD = $null
        $env:IBWAPI_SKIPCERTCHECK = $null
        $env:IBWAPI_VAULT_NAME = $null
        $env:IBWAPI_VAULT_PASS = $null
        $env:IBWAPI_VAULT_SECRET_TEMPLATE = $null
        Import-Module (Join-Path $PSScriptRoot '..\Posh-IBWAPI\Posh-IBWAPI.psd1')

        # setup fake profile export location
        $fakeConfigFolder = 'TestDrive:\config'
        $fakeConfigFile   = 'TestDrive:\config\posh-ibwapi.json'

        # setup fake credentials to use
        $fakePass1 = ConvertTo-SecureString 'password1' -AsPlainText -Force
        $fakeCred1 = [pscredential]::new('admin1',$fakePass1)
        $fakePass2 = ConvertTo-SecureString 'password2' -AsPlainText -Force
        $fakeCred2 = [pscredential]::new('admin2',$fakePass2)

        # setup fake config
        $fakeConfig = @{
            CurrentProfile = 'prof1'
            Profiles = @{
                'prof1' = @{
                    WAPIHost = 'gm1'
                    WAPIVersion = '1.0'
                    Credential = @{
                        Username = $fakeCred1.UserName
                        Password = $fakeCred1.Password | ConvertFrom-SecureString
                    }
                    SkipCertificateCheck = $false
                }
                'prof2' = @{
                    WAPIHost = 'gm2'
                    WAPIVersion = '2.0'
                    Credential = @{
                        Username = $fakeCred2.UserName
                        Password = $fakeCred2.Password | ConvertFrom-SecureString
                    }
                    SkipCertificateCheck = $true
                }
            }
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
            Current = $false
        }

    }

    Context "No existing config" {

        BeforeAll {
            Mock Get-ConfigFolder -ModuleName Posh-IBWAPI { $fakeConfigFolder }
            Mock Get-ConfigFile -ModuleName Posh-IBWAPI { $fakeConfigFile }
        }

        It "Initializes everything (local)" {
            InModuleScope Posh-IBWAPI {

                Import-IBConfig

                $script:CurrentProfile | Should -Be ''

                $script:Profiles       | Should -BeOfType System.Collections.Hashtable
                $script:Profiles.Keys  | Should -HaveCount 0
                $script:Sessions       | Should -BeOfType System.Collections.Hashtable
                $script:Sessions.Keys  | Should -HaveCount 0
                $script:Schemas        | Should -BeOfType System.Collections.Hashtable
                $script:Schemas.Keys   | Should -HaveCount 0
            }
        }

        It "Initializes everything (vault)" {
            Mock -ModuleName Posh-IBWAPI Get-VaultConfig { $fakeVaultConfig }
            Mock -ModuleName Posh-IBWAPI Get-VaultProfiles { }

            InModuleScope Posh-IBWAPI {

                Import-IBConfig

                $script:CurrentProfile | Should -Be ''

                $script:Profiles       | Should -BeOfType System.Collections.Hashtable
                $script:Profiles.Keys  | Should -HaveCount 0
                $script:Sessions       | Should -BeOfType System.Collections.Hashtable
                $script:Sessions.Keys  | Should -HaveCount 0
                $script:Schemas        | Should -BeOfType System.Collections.Hashtable
                $script:Schemas.Keys   | Should -HaveCount 0
            }
        }
    }

    Context "Corrupt/Unparseable config" {

        BeforeAll {
            Mock Get-ConfigFolder -ModuleName Posh-IBWAPI { $fakeConfigFolder }
            Mock Get-ConfigFile -ModuleName Posh-IBWAPI { $fakeConfigFile }
            Mock Write-Warning -ModuleName Posh-IBWAPI { }

            # write out some unparsable json to the file
            New-Item $fakeConfigFolder -Type Directory -ErrorAction Ignore
            '{"partial":"' | Out-File $fakeConfigFile -Encoding utf8
        }

        It "Warns on invalid config (local)" {
            InModuleScope Posh-IBWAPI {

                { Import-IBConfig } | Should -Not -Throw

                Should -Invoke Write-Warning -ModuleName Posh-IBWAPI

                $script:CurrentProfile | Should -Be ''

                $script:Profiles       | Should -BeOfType System.Collections.Hashtable
                $script:Profiles.Keys  | Should -HaveCount 0
                $script:Sessions       | Should -BeOfType System.Collections.Hashtable
                $script:Sessions.Keys  | Should -HaveCount 0
                $script:Schemas        | Should -BeOfType System.Collections.Hashtable
                $script:Schemas.Keys   | Should -HaveCount 0
            }
        }

    }

    Context "Valid Current Config" {

        BeforeAll {
            Mock Get-ConfigFolder -ModuleName Posh-IBWAPI { $fakeConfigFolder }
            Mock Get-ConfigFile -ModuleName Posh-IBWAPI { $fakeConfigFile }
            Mock Write-Warning -ModuleName Posh-IBWAPI {}

            # write out a valid config to the file
            New-Item $fakeConfigFolder -Type Directory -ErrorAction Ignore
            $fakeConfig | ConvertTo-Json -Depth 10 | Out-File $fakeConfigFile -Encoding utf8
        }

        It "Converts automatically (local)" {
            InModuleScope Posh-IBWAPI {
                { Import-IBConfig } | Should -Not -Throw

                $script:CurrentProfile | Should -Be 'prof1'

                $script:Profiles.Keys   | Should -HaveCount 2
                $script:Profiles['prof1'] | Should -Not -BeNullOrEmpty
                $script:Profiles['prof2'] | Should -Not -BeNullOrEmpty

                $prof1 = $script:Profiles['prof1']
                $prof1.WAPIHost | Should -Be 'gm1'
                $prof1.WAPIVersion | Should -Be '1.0'
                $prof1.Credential.Username | Should -Be 'admin1'
                $prof1.Credential.GetNetworkCredential().Password | Should -Be 'password1'
                $prof1.SkipCertificateCheck | Should -BeFalse

                $prof2 = $script:Profiles['prof2']
                $prof2.WAPIHost | Should -Be 'gm2'
                $prof2.WAPIVersion | Should -Be '2.0'
                $prof2.Credential.Username | Should -Be 'admin2'
                $prof2.Credential.GetNetworkCredential().Password | Should -Be 'password2'
                $prof2.SkipCertificateCheck | Should -BeTrue
            }
        }

        It "Converts automatically (vault)" {

            Mock -ModuleName Posh-IBWAPI Get-VaultConfig { $fakeVaultConfig }
            Mock -ModuleName Posh-IBWAPI Get-VaultProfiles { return @{
                prof1 = $fakeVaultProfile1
                prof2 = $fakeVaultProfile2
            } }

            InModuleScope Posh-IBWAPI {
                { Import-IBConfig } | Should -Not -Throw

                $script:CurrentProfile | Should -Be 'prof1'

                $script:Profiles.Keys   | Should -HaveCount 2
                $script:Profiles['prof1'] | Should -Not -BeNullOrEmpty
                $script:Profiles['prof2'] | Should -Not -BeNullOrEmpty

                $prof1 = $script:Profiles['prof1']
                $prof1.WAPIHost | Should -Be 'gm1'
                $prof1.WAPIVersion | Should -Be '1.0'
                $prof1.Credential.Username | Should -Be 'admin1'
                $prof1.Credential.GetNetworkCredential().Password | Should -Be 'password1'
                $prof1.SkipCertificateCheck | Should -BeFalse

                $prof2 = $script:Profiles['prof2']
                $prof2.WAPIHost | Should -Be 'gm2'
                $prof2.WAPIVersion | Should -Be '2.0'
                $prof2.Credential.Username | Should -Be 'admin2'
                $prof2.Credential.GetNetworkCredential().Password | Should -Be 'password2'
                $prof2.SkipCertificateCheck | Should -BeTrue
            }
        }

    }

    Context "Environment Variable Profile" {

        BeforeAll {
            Mock Get-ConfigFolder -ModuleName Posh-IBWAPI { $fakeConfigFolder }
            Mock Get-ConfigFile -ModuleName Posh-IBWAPI { $fakeConfigFile }

            # write out a valid config to the file
            New-Item $fakeConfigFolder -Type Directory -ErrorAction Ignore
            $fakeConfig | ConvertTo-Json -Depth 10 | Out-File $fakeConfigFile -Encoding utf8
        }

        It "Warns on no version" {
            $env:IBWAPI_HOST = 'envgm'

            InModuleScope Posh-IBWAPI {
                Mock Write-Warning {}

                { Import-IBConfig } | Should -Not -Throw

                Should -Invoke Write-Warning -ParameterFilter {
                    $Message -like '*IBWAPI_VERSION*'
                }

                $script:CurrentProfile | Should -Be 'prof1'
            }
        }

        It "Warns on invalid version" {
            $env:IBWAPI_VERSION = 'asdf'

            InModuleScope Posh-IBWAPI {
                Mock Write-Warning {}

                { Import-IBConfig } | Should -Not -Throw

                Should -Invoke Write-Warning -ParameterFilter {
                    $Message -like '*IBWAPI_VERSION*'
                }

                $script:CurrentProfile | Should -Be 'prof1'
            }
        }

        It "Warns on no username" {
            $env:IBWAPI_VERSION = '2.1'

            InModuleScope Posh-IBWAPI {
                Mock Write-Warning {}

                { Import-IBConfig } | Should -Not -Throw

                Should -Invoke Write-Warning -ParameterFilter {
                    $Message -like '*IBWAPI_USERNAME*'
                }

                $script:CurrentProfile | Should -Be 'prof1'
            }
        }

        It "Warns on no password" {
            $env:IBWAPI_USERNAME = 'envuser'

            InModuleScope Posh-IBWAPI {
                Mock Write-Warning {}

                { Import-IBConfig } | Should -Not -Throw

                Should -Invoke Write-Warning -ParameterFilter {
                    $Message -like '*IBWAPI_PASSWORD*'
                }

                $script:CurrentProfile | Should -Be 'prof1'
            }
        }

        It "Uses complete env profile" {
            $env:IBWAPI_PASSWORD = 'envpass'

            InModuleScope Posh-IBWAPI {
                Mock Write-Warning {}

                { Import-IBConfig } | Should -Not -Throw

                Should -Not -Invoke Write-Warning

                $script:CurrentProfile | Should -Be 'ENV'
                $script:Profiles.ENV.SkipCertificateCheck | Should -BeFalse
            }
        }

        It "Uses complete env profile with SKIPCERTCHECK" {
            $env:IBWAPI_SKIPCERTCHECK = 'True'

            InModuleScope Posh-IBWAPI {
                Mock Write-Warning {}

                { Import-IBConfig } | Should -Not -Throw

                Should -Not -Invoke Write-Warning

                $script:CurrentProfile | Should -Be 'ENV'
                $script:Profiles.ENV.SkipCertificateCheck | Should -BeTrue
            }
        }

    }

    AfterAll {
        $env:IBWAPI_HOST = $null
        $env:IBWAPI_VERSION = $null
        $env:IBWAPI_USERNAME = $null
        $env:IBWAPI_PASSWORD = $null
        $env:IBWAPI_SKIPCERTCHECK = $null
    }
}
