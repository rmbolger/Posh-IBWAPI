BeforeAll {
    Import-Module (Join-Path $PSScriptRoot '..\Posh-IBWAPI\Posh-IBWAPI.psd1')

    # setup fake profile export location
    $fakeConfigFolder = 'TestDrive:\config'
    $fakeConfigFile   = 'TestDrive:\config\posh-ibwapi.json'

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

Describe "Export-IBConfig" {

    Context "No profiles" {

        BeforeAll {
            Mock -ModuleName Posh-IBWAPI Get-ConfigFolder { $fakeConfigFolder }
            Mock -ModuleName Posh-IBWAPI Get-ConfigFile { $fakeConfigFile }
            Mock -ModuleName Posh-IBWAPI Get-Profiles { return @{} }
            Mock -ModuleName Posh-IBWAPI Get-CurrentProfile { return [string]::Empty }
        }

        It "Saves nothing" {
            InModuleScope Posh-IBWAPI {

                Import-IBConfig
                Export-IBConfig

                Get-ConfigFile | Should -Not -Exist
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

        It "Saves the profile" {
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

        It "Saves the profile" {
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
