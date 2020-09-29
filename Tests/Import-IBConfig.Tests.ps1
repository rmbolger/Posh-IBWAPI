BeforeAll {
    Import-Module (Join-Path $PSScriptRoot '..\Posh-IBWAPI\Posh-IBWAPI.psd1')

    # setup fake profile export location
    $fakeConfigFolder = 'TestDrive:\config'
    $fakeConfigFile   = 'TestDrive:\config\posh-ibwapi.json'

    # setup fake credentials to use
    $fakePass1 = ConvertTo-SecureString 'password1' -AsPlainText -Force
    $fakeCred1 = New-Object PSCredential 'admin1',$fakePass1
    $fakePass2 = ConvertTo-SecureString 'password2' -AsPlainText -Force
    $fakeCred2 = New-Object PSCredential 'admin2',$fakePass2

    # setup fake V1 config
    $fakeV1Config = @{
        CurrentHost = 'gm1'
        Hosts = @{
            'gm1' = @{
                WAPIHost = 'gm1'
                WAPIVersion = '1.0'
                Credential = @{
                    Username = $fakeCred1.UserName
                    Password = $fakeCred1.Password | ConvertFrom-SecureString
                }
            }
            'gm2' = @{
                WAPIHost = 'gm2'
                WAPIVersion = '2.0'
                Credential = @{
                    Username = $fakeCred2.UserName
                    Password = $fakeCred2.Password | ConvertFrom-SecureString
                }
                IgnoreCertificateValidation = $true
            }
        }
    }

    # setup fake current config
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
}

Describe "Import-IBConfig" {

    Context "No existing config" {

        BeforeAll {
            Mock -ModuleName Posh-IBWAPI Get-ConfigFolder { $fakeConfigFolder }
            Mock -ModuleName Posh-IBWAPI Get-ConfigFile { $fakeConfigFile }
        }

        It "Initializes everything" {
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
            Mock -ModuleName Posh-IBWAPI Get-ConfigFolder { $fakeConfigFolder }
            Mock -ModuleName Posh-IBWAPI Get-ConfigFile { $fakeConfigFile }
            Mock Write-Warning { }

            # write out some unparsable json to the file
            New-Item $fakeConfigFolder -Type Directory -ErrorAction Ignore
            '{"partial":"' | Out-File $fakeConfigFile -Encoding utf8
        }

        It "Warns on invalid config" {
            InModuleScope Posh-IBWAPI {

                { Import-IBConfig } | Should -Not -Throw

                Should -Invoke Write-Warning

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

    Context "Old V1 Config" {

        BeforeAll {
            Mock -ModuleName Posh-IBWAPI Get-ConfigFolder { $fakeConfigFolder }
            Mock -ModuleName Posh-IBWAPI Get-ConfigFile { $fakeConfigFile }
            Mock Write-Warning {}

            # write out a v1 config to the file
            New-Item $fakeConfigFolder -Type Directory -ErrorAction Ignore
            $fakeV1Config | ConvertTo-Json -Depth 10 | Out-File $fakeConfigFile -Encoding utf8
        }

        It "Converts automatically" {
            InModuleScope Posh-IBWAPI {
                { Import-IBConfig } | Should -Not -Throw

                $script:CurrentProfile | Should -Be 'gm1'

                $script:Profiles.Keys   | Should -HaveCount 2
                $script:Profiles['gm1'] | Should -Not -BeNullOrEmpty
                $script:Profiles['gm2'] | Should -Not -BeNullOrEmpty

                $prof1 = $script:Profiles['gm1']
                $prof1.WAPIHost | Should -Be 'gm1'
                $prof1.WAPIVersion | Should -Be '1.0'
                $prof1.Credential.Username | Should -Be 'admin1'
                $prof1.Credential.GetNetworkCredential().Password | Should -Be 'password1'
                $prof1.SkipCertificateCheck | Should -BeFalse

                $prof2 = $script:Profiles['gm2']
                $prof2.WAPIHost | Should -Be 'gm2'
                $prof2.WAPIVersion | Should -Be '2.0'
                $prof2.Credential.Username | Should -Be 'admin2'
                $prof2.Credential.GetNetworkCredential().Password | Should -Be 'password2'
                $prof2.SkipCertificateCheck | Should -BeTrue

                "$(Get-ConfigFile).v1" | Should -Exist
            }
        }
    }

    Context "Valid Current Config" {

        BeforeAll {
            Mock -ModuleName Posh-IBWAPI Get-ConfigFolder { $fakeConfigFolder }
            Mock -ModuleName Posh-IBWAPI Get-ConfigFile { $fakeConfigFile }
            Mock Write-Warning {}

            # write out a valid config to the file
            New-Item $fakeConfigFolder -Type Directory -ErrorAction Ignore
            $fakeConfig | ConvertTo-Json -Depth 10 | Out-File $fakeConfigFile -Encoding utf8
        }

        It "Converts automatically" {
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

}
