BeforeAll {
    Import-Module (Join-Path $PSScriptRoot '..\Posh-IBWAPI\Posh-IBWAPI.psd1')

    # setup fake profiles for mocking with
    $fakePass1 = ConvertTo-SecureString 'password1' -AsPlainText -Force
    $fakeCred1 = New-Object PSCredential 'admin1',$fakePass1
    $prof1 = @{
        WAPIHost = 'gm1'
        WAPIVersion = '1.0'
        Credential = $fakeCred1
        SkipCertificateCheck = $false
    }

    $fakePass2 = ConvertTo-SecureString 'password2' -AsPlainText -Force
    $fakeCred2 = New-Object PSCredential 'admin2',$fakePass2
    $prof2 = @{
        WAPIHost = 'gm2'
        WAPIVersion = '2.0'
        Credential = $fakeCred2
        SkipCertificateCheck = $true
    }
}

Describe "Get-IBConfig" {

    Context "No profiles" {

        BeforeAll {
            Mock -ModuleName Posh-IBWAPI Get-Profiles { return @{} }
            Mock -ModuleName Posh-IBWAPI Get-CurrentProfile { return [string]::Empty }
        }

        It "Returns null with no parameters" {
            Get-IBConfig | Should -BeExactly $null
        }
        It "Returns null with specific profile name" {
            Get-IBConfig -ProfileName fake | Should -BeExactly $null
        }
        It "Returns null with -List" {
            Get-IBConfig -List | Should -BeExactly $null
        }

    }

    Context "1 active profile" {
        BeforeAll {
            Mock -ModuleName Posh-IBWAPI Get-Profiles { return @{ 'prof1' = $prof1 } }
            Mock -ModuleName Posh-IBWAPI Get-CurrentProfile { return 'prof1' }
        }

        It "Returns the profile with no parameters" {
            $config = Get-IBConfig
            $config                      | Should -Not -BeNullOrEmpty
            $config.PSTypeNames          | Should -Contain PoshIBWAPI.IBConfig
            $config.ProfileName          | Should -Be 'prof1'
            $config.WAPIHost             | Should -Be 'gm1'
            $config.WAPIVersion          | Should -Be '1.0'
            $config.Credential           | Should -Be $fakeCred1
            $config.SkipCertificateCheck | Should -BeFalse
        }

        It "Returns the profile with specific profile name" {
            $config = Get-IBConfig -ProfileName prof1
            $config                      | Should -Not -BeNullOrEmpty
            $config.PSTypeNames          | Should -Contain PoshIBWAPI.IBConfig
            $config.ProfileName          | Should -Be 'prof1'
            $config.WAPIHost             | Should -Be 'gm1'
            $config.WAPIVersion          | Should -Be '1.0'
            $config.Credential           | Should -Be $fakeCred1
            $config.SkipCertificateCheck | Should -BeFalse
        }

        It "Returns null with wrong profile name" {
            Get-IBConfig -ProfileName badname | Should -BeExactly $null
        }

        It "Returns the profile with -List" {
            $configs = Get-IBConfig -List
            $configs                      | Should -Not -BeNullOrEmpty
            $configs.PSTypeNames          | Should -Contain PoshIBWAPI.IBConfig
            $configs.ProfileName          | Should -Be 'prof1'
            $configs.WAPIHost             | Should -Be 'gm1'
            $configs.WAPIVersion          | Should -Be '1.0'
            $configs.Credential           | Should -Be $fakeCred1
            $configs.SkipCertificateCheck | Should -BeFalse
        }
    }

    Context "1 inactive profile" {
        BeforeAll {
            Mock -ModuleName Posh-IBWAPI Get-Profiles { return @{ 'prof1' = $prof1 } }
            Mock -ModuleName Posh-IBWAPI Get-CurrentProfile { return [string]::Empty }
        }

        It "Returns null with no parameters" {
            Get-IBConfig | Should -BeExactly $null
        }

        It "Returns the profile with specific profile name" {
            $config = Get-IBConfig -ProfileName prof1
            $config                      | Should -Not -BeNullOrEmpty
            $config.PSTypeNames          | Should -Contain PoshIBWAPI.IBConfig
            $config.ProfileName          | Should -Be 'prof1'
            $config.WAPIHost             | Should -Be 'gm1'
            $config.WAPIVersion          | Should -Be '1.0'
            $config.Credential           | Should -Be $fakeCred1
            $config.SkipCertificateCheck | Should -BeFalse
        }

        It "Returns null with wrong profile name" {
            Get-IBConfig -ProfileName badname | Should -BeExactly $null
        }

        It "Returns the profile with -List" {
            $configs = Get-IBConfig -List
            $configs                      | Should -Not -BeNullOrEmpty
            $configs.PSTypeNames          | Should -Contain PoshIBWAPI.IBConfig
            $configs.ProfileName          | Should -Be 'prof1'
            $configs.WAPIHost             | Should -Be 'gm1'
            $configs.WAPIVersion          | Should -Be '1.0'
            $configs.Credential           | Should -Be $fakeCred1
            $configs.SkipCertificateCheck | Should -BeFalse
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

        It "Returns the active profile with no parameters" {
            $config = Get-IBConfig
            $config                      | Should -Not -BeNullOrEmpty
            $config.PSTypeNames          | Should -Contain PoshIBWAPI.IBConfig
            $config.ProfileName          | Should -Be 'prof1'
            $config.WAPIHost             | Should -Be 'gm1'
            $config.WAPIVersion          | Should -Be '1.0'
            $config.Credential           | Should -Be $fakeCred1
            $config.SkipCertificateCheck | Should -BeFalse
        }

        It "Returns another profile with specific profile name" {
            $config = Get-IBConfig -ProfileName prof2
            $config                      | Should -Not -BeNullOrEmpty
            $config.PSTypeNames          | Should -Contain PoshIBWAPI.IBConfig
            $config.ProfileName          | Should -Be 'prof2'
            $config.WAPIHost             | Should -Be 'gm2'
            $config.WAPIVersion          | Should -Be '2.0'
            $config.Credential           | Should -Be $fakeCred2
            $config.SkipCertificateCheck | Should -BeTrue
        }

        It "Returns null with wrong profile name" {
            Get-IBConfig -ProfileName badname | Should -BeExactly $null
        }

        It "Returns all profiles with -List" {
            $configs = Get-IBConfig -List
            $configs.Keys                    | Should -HaveCount 2
            $configs[0]                      | Should -Not -BeNullOrEmpty
            $configs[0].PSTypeNames          | Should -Contain PoshIBWAPI.IBConfig
            $configs[0].ProfileName          | Should -Be 'prof1'
            $configs[0].WAPIHost             | Should -Be 'gm1'
            $configs[0].WAPIVersion          | Should -Be '1.0'
            $configs[0].Credential           | Should -Be $fakeCred1
            $configs[0].SkipCertificateCheck | Should -BeFalse
            $configs[1]                      | Should -Not -BeNullOrEmpty
            $configs[1].PSTypeNames          | Should -Contain PoshIBWAPI.IBConfig
            $configs[1].ProfileName          | Should -Be 'prof2'
            $configs[1].WAPIHost             | Should -Be 'gm2'
            $configs[1].WAPIVersion          | Should -Be '2.0'
            $configs[1].Credential           | Should -Be $fakeCred2
            $configs[1].SkipCertificateCheck | Should -BeTrue
        }
    }
}
