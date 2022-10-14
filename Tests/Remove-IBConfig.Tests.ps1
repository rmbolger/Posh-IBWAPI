Describe "Remove-IBConfig" {

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

        # setup a fake profile body to use
        $fakePass = ConvertTo-SecureString 'password1' -AsPlainText -Force
        $fakeProfile = @{
            WAPIHost = 'gm1'
            WAPIVersion = '1.0'
            Credential = @{
                Username = 'admin1'
                Password = $fakePass | ConvertFrom-SecureString
            }
            SkipCertificateCheck = $false
        }
    }

    Context "No existing config" {

        BeforeAll {
            Mock Get-ConfigFolder -ModuleName Posh-IBWAPI { $fakeConfigFolder }
            Mock Get-ConfigFile -ModuleName Posh-IBWAPI { $fakeConfigFile }
            Mock Write-Warning -ModuleName Posh-IBWAPI {}
        }

        BeforeEach {
            InModuleScope Posh-IBWAPI { Import-IBConfig }
        }

        It "Doesn't allow empty profile names" {

            { Remove-IBConfig -ProfileName '' } | Should -Throw
            { Remove-IBConfig -ProfileName $null } | Should -Throw
        }

        It "Gracefully deals with bad requests" {

            $prof = [pscustomobject]@{ProfileName='prof1'}

            { Remove-IBConfig -AllProfiles }        | Should -Not -Throw
            { Remove-IBConfig -AllProfiles:$false } | Should -Not -Throw
            { Remove-IBConfig 'prof1' }             | Should -Not -Throw
            { 'prof1' | Remove-IBConfig }           | Should -Not -Throw
            { $prof | Remove-IBConfig }             | Should -Not -Throw

            Remove-IBConfig 'prof1'
            Should -Invoke Write-Warning -ModuleName Posh-IBWAPI

            'prof1' | Remove-IBConfig
            Should -Invoke Write-Warning -ModuleName Posh-IBWAPI

            $prof | Remove-IBConfig
            Should -Invoke Write-Warning -ModuleName Posh-IBWAPI
        }
    }

    Context "1 active profile" {

        BeforeAll {
            Mock Get-ConfigFolder -ModuleName Posh-IBWAPI { $fakeConfigFolder }
            Mock Get-ConfigFile -ModuleName Posh-IBWAPI { $fakeConfigFile }
            Mock Write-Warning -ModuleName Posh-IBWAPI {}

            New-Item $fakeConfigFolder -Type Directory -ErrorAction Ignore
        }

        BeforeEach {
            @{
                CurrentProfile = 'prof1'
                Profiles = @{
                    'prof1' = $fakeProfile
                }
            } | ConvertTo-Json -Depth 10 | Out-File $fakeConfigFile -Encoding utf8

            InModuleScope Posh-IBWAPI { Import-IBConfig }
        }

        It "Removes active profile with no params" {

            Remove-IBConfig

            # make sure what's left in memory is correct
            Get-IBConfig -List         | Should -HaveCount 0
            Get-IBConfig               | Should -BeExactly $null
            Get-IBConfig 'prof1'       | Should -BeExactly $null

            # make sure what's left on disk is correct
            $fakeConfigFile | Should -Not -Exist
        }

        It "Removes specified profile" {

            Remove-IBConfig -ProfileName prof1

            # make sure what's left in memory is correct
            Get-IBConfig -List         | Should -HaveCount 0
            Get-IBConfig               | Should -BeExactly $null
            Get-IBConfig 'prof1'       | Should -BeExactly $null

            # make sure what's left on disk is correct
            $fakeConfigFile | Should -Not -Exist
        }

        It "Removes specified profile via pipeline" {

            'prof1' | Remove-IBConfig

            # make sure what's left in memory is correct
            Get-IBConfig -List         | Should -HaveCount 0
            Get-IBConfig               | Should -BeExactly $null
            Get-IBConfig 'prof1'       | Should -BeExactly $null

            # make sure what's left on disk is correct
            $fakeConfigFile | Should -Not -Exist
        }

        It "Removes specified profile via pipeline by property name" {

            $prof = [pscustomobject]@{ProfileName='prof1'}
            $prof | Remove-IBConfig

            # make sure what's left in memory is correct
            Get-IBConfig -List         | Should -HaveCount 0
            Get-IBConfig               | Should -BeExactly $null
            Get-IBConfig 'prof1'       | Should -BeExactly $null

            # make sure what's left on disk is correct
            $fakeConfigFile | Should -Not -Exist
        }

        It "Removes all profiles with -AllProfiles" {

            Remove-IBConfig -AllProfiles

            # make sure what's left in memory is correct
            Get-IBConfig -List         | Should -HaveCount 0
            Get-IBConfig               | Should -BeExactly $null
            Get-IBConfig 'prof1'       | Should -BeExactly $null

            # make sure what's left on disk is correct
            $fakeConfigFile | Should -Not -Exist
        }
    }

    Context "1 inactive profile" {

        BeforeAll {
            Mock Get-ConfigFolder -ModuleName Posh-IBWAPI { $fakeConfigFolder }
            Mock Get-ConfigFile -ModuleName Posh-IBWAPI { $fakeConfigFile }
            Mock Write-Warning -ModuleName Posh-IBWAPI {}

            New-Item $fakeConfigFolder -Type Directory -ErrorAction Ignore
        }

        BeforeEach {
            @{
                CurrentProfile = ''
                Profiles = @{
                    'prof1' = $fakeProfile
                }
            } | ConvertTo-Json -Depth 10 | Out-File $fakeConfigFile -Encoding utf8

            InModuleScope Posh-IBWAPI { Import-IBConfig }
        }

        It "Removes nothing with no params" {

            Remove-IBConfig

            # make sure what's left in memory is correct
            Get-IBConfig -List         | Should -HaveCount 1
            Get-IBConfig               | Should -BeExactly $null
            Get-IBConfig 'prof1'       | Should -Not -BeNullOrEmpty

            # make sure what's left on disk is correct
            $json = Get-Content $fakeConfigFile -Raw | ConvertFrom-Json
            $json.CurrentProfile   | Should -Be ''
            $json.Profiles.'prof1' | Should -Not -BeNullOrEmpty
        }

        It "Removes specified profile" {

            Remove-IBConfig -ProfileName prof1

            # make sure what's left in memory is correct
            Get-IBConfig -List         | Should -HaveCount 0
            Get-IBConfig               | Should -BeExactly $null
            Get-IBConfig 'prof1'       | Should -BeExactly $null

            # make sure what's left on disk is correct
            $fakeConfigFile | Should -Not -Exist
        }

        It "Removes specified profile via pipeline" {

            'prof1' | Remove-IBConfig

            # make sure what's left in memory is correct
            Get-IBConfig -List         | Should -HaveCount 0
            Get-IBConfig               | Should -BeExactly $null
            Get-IBConfig 'prof1'       | Should -BeExactly $null

            # make sure what's left on disk is correct
            $fakeConfigFile | Should -Not -Exist
        }

        It "Removes specified profile via pipeline by property name" {

            $prof = [pscustomobject]@{ProfileName='prof1'}
            $prof | Remove-IBConfig

            # make sure what's left in memory is correct
            Get-IBConfig -List         | Should -HaveCount 0
            Get-IBConfig               | Should -BeExactly $null
            Get-IBConfig 'prof1'       | Should -BeExactly $null

            # make sure what's left on disk is correct
            $fakeConfigFile | Should -Not -Exist
        }

        It "Removes all profiles with -AllProfiles" {

            Remove-IBConfig -AllProfiles

            # make sure what's left in memory is correct
            Get-IBConfig -List         | Should -HaveCount 0
            Get-IBConfig               | Should -BeExactly $null
            Get-IBConfig 'prof1'       | Should -BeExactly $null

            # make sure what's left on disk is correct
            $fakeConfigFile | Should -Not -Exist
        }
    }

    Context "2 profiles 1 active" {

        BeforeAll {
            Mock Get-ConfigFolder -ModuleName Posh-IBWAPI { $fakeConfigFolder }
            Mock Get-ConfigFile -ModuleName Posh-IBWAPI { $fakeConfigFile }
            Mock Write-Warning -ModuleName Posh-IBWAPI {}

            New-Item $fakeConfigFolder -Type Directory -ErrorAction Ignore
        }

        BeforeEach {
            @{
                CurrentProfile = 'prof1'
                Profiles = @{
                    'prof1' = $fakeProfile
                    'prof2' = $fakeProfile
                }
            } | ConvertTo-Json -Depth 10 | Out-File $fakeConfigFile -Encoding utf8

            InModuleScope Posh-IBWAPI { Import-IBConfig }
        }

        It "Removes active profile with no params" {

            Remove-IBConfig

            # make sure what's left in memory is correct
            Get-IBConfig -List         | Should -HaveCount 1
            (Get-IBConfig).ProfileName | Should -Be 'prof2'
            Get-IBConfig 'prof1'       | Should -BeExactly $null
            Get-IBConfig 'prof2'       | Should -Not -BeNullOrEmpty

            # make sure what's left on disk is correct
            $json = Get-Content $fakeConfigFile -Raw | ConvertFrom-Json
            $json.CurrentProfile   | Should -Be 'prof2'
            $json.Profiles.'prof1' | Should -BeExactly $null
            $json.Profiles.'prof2' | Should -Not -BeNullOrEmpty
        }

        It "Removes specified inactive profile" {

            Remove-IBConfig -ProfileName prof2

            # make sure what's left in memory is correct
            Get-IBConfig -List         | Should -HaveCount 1
            (Get-IBConfig).ProfileName | Should -Be 'prof1'
            Get-IBConfig 'prof1'       | Should -Not -BeNullOrEmpty
            Get-IBConfig 'prof2'       | Should -BeExactly $null

            # make sure what's left on disk is correct
            $json = Get-Content $fakeConfigFile -Raw | ConvertFrom-Json
            $json.CurrentProfile   | Should -Be 'prof1'
            $json.Profiles.'prof1' | Should -Not -BeNullOrEmpty
            $json.Profiles.'prof2' | Should -BeExactly $null
        }

        It "Removes specified inactive profile via pipeline" {

            'prof2' | Remove-IBConfig

            # make sure what's left in memory is correct
            Get-IBConfig -List         | Should -HaveCount 1
            (Get-IBConfig).ProfileName | Should -Be 'prof1'
            Get-IBConfig 'prof1'       | Should -Not -BeNullOrEmpty
            Get-IBConfig 'prof2'       | Should -BeExactly $null

            # make sure what's left on disk is correct
            $json = Get-Content $fakeConfigFile -Raw | ConvertFrom-Json
            $json.CurrentProfile   | Should -Be 'prof1'
            $json.Profiles.'prof1' | Should -Not -BeNullOrEmpty
            $json.Profiles.'prof2' | Should -BeExactly $null
        }

        It "Removes specified inactive profile via pipeline by property name" {

            $prof = [pscustomobject]@{ProfileName='prof2'}
            $prof | Remove-IBConfig

            # make sure what's left in memory is correct
            Get-IBConfig -List         | Should -HaveCount 1
            (Get-IBConfig).ProfileName | Should -Be 'prof1'
            Get-IBConfig 'prof1'       | Should -Not -BeNullOrEmpty
            Get-IBConfig 'prof2'       | Should -BeExactly $null

            # make sure what's left on disk is correct
            $json = Get-Content $fakeConfigFile -Raw | ConvertFrom-Json
            $json.CurrentProfile   | Should -Be 'prof1'
            $json.Profiles.'prof1' | Should -Not -BeNullOrEmpty
            $json.Profiles.'prof2' | Should -BeExactly $null
        }

        It "Removes all profiles with -AllProfiles" {

            Remove-IBConfig -AllProfiles

            # make sure what's left in memory is correct
            Get-IBConfig -List         | Should -HaveCount 0
            Get-IBConfig               | Should -BeExactly $null
            Get-IBConfig 'prof1'       | Should -BeExactly $null
            Get-IBConfig 'prof2'       | Should -BeExactly $null

            # make sure what's left on disk is correct
            $fakeConfigFile | Should -Not -Exist
        }
    }

    Context "2 profiles neither active" {

        BeforeAll {
            Mock Get-ConfigFolder -ModuleName Posh-IBWAPI { $fakeConfigFolder }
            Mock Get-ConfigFile -ModuleName Posh-IBWAPI { $fakeConfigFile }
            Mock Write-Warning -ModuleName Posh-IBWAPI {}

            New-Item $fakeConfigFolder -Type Directory -ErrorAction Ignore
        }

        BeforeEach {
            @{
                CurrentProfile = ''
                Profiles = @{
                    'prof1' = $fakeProfile
                    'prof2' = $fakeProfile
                }
            } | ConvertTo-Json -Depth 10 | Out-File $fakeConfigFile -Encoding utf8

            InModuleScope Posh-IBWAPI { Import-IBConfig }
        }

        It "Removes nothing with no params" {

            Remove-IBConfig

            # make sure what's left in memory is correct
            Get-IBConfig -List         | Should -HaveCount 2
            Get-IBConfig               | Should -BeExactly $null
            Get-IBConfig 'prof1'       | Should -Not -BeNullOrEmpty
            Get-IBConfig 'prof2'       | Should -Not -BeNullOrEmpty

            # make sure what's left on disk is correct
            $json = Get-Content $fakeConfigFile -Raw | ConvertFrom-Json
            $json.CurrentProfile   | Should -Be ''
            $json.Profiles.'prof1' | Should -Not -BeNullOrEmpty
            $json.Profiles.'prof2' | Should -Not -BeNullOrEmpty
        }

        It "Removes specified profile" {

            Remove-IBConfig -ProfileName prof2

            # make sure what's left in memory is correct
            Get-IBConfig -List         | Should -HaveCount 1
            Get-IBConfig               | Should -BeExactly $null
            Get-IBConfig 'prof1'       | Should -Not -BeNullOrEmpty
            Get-IBConfig 'prof2'       | Should -BeExactly $null

            # make sure what's left on disk is correct
            $json = Get-Content $fakeConfigFile -Raw | ConvertFrom-Json
            $json.CurrentProfile   | Should -Be ''
            $json.Profiles.'prof1' | Should -Not -BeNullOrEmpty
            $json.Profiles.'prof2' | Should -BeExactly $null
        }

        It "Removes specified profile via pipeline" {

            'prof2' | Remove-IBConfig

            # make sure what's left in memory is correct
            Get-IBConfig -List         | Should -HaveCount 1
            Get-IBConfig               | Should -BeExactly $null
            Get-IBConfig 'prof1'       | Should -Not -BeNullOrEmpty
            Get-IBConfig 'prof2'       | Should -BeExactly $null

            # make sure what's left on disk is correct
            $json = Get-Content $fakeConfigFile -Raw | ConvertFrom-Json
            $json.CurrentProfile   | Should -Be ''
            $json.Profiles.'prof1' | Should -Not -BeNullOrEmpty
            $json.Profiles.'prof2' | Should -BeExactly $null
        }

        It "Removes specified inactive profile via pipeline by property name" {

            $prof = [pscustomobject]@{ProfileName='prof2'}
            $prof | Remove-IBConfig

            # make sure what's left in memory is correct
            Get-IBConfig -List         | Should -HaveCount 1
            Get-IBConfig               | Should -BeExactly $null
            Get-IBConfig 'prof1'       | Should -Not -BeNullOrEmpty
            Get-IBConfig 'prof2'       | Should -BeExactly $null

            # make sure what's left on disk is correct
            $json = Get-Content $fakeConfigFile -Raw | ConvertFrom-Json
            $json.CurrentProfile   | Should -Be ''
            $json.Profiles.'prof1' | Should -Not -BeNullOrEmpty
            $json.Profiles.'prof2' | Should -BeExactly $null
        }

        It "Removes all profiles with -AllProfiles" {

            Remove-IBConfig -AllProfiles

            # make sure what's left in memory is correct
            Get-IBConfig -List         | Should -HaveCount 0
            Get-IBConfig               | Should -BeExactly $null
            Get-IBConfig 'prof1'       | Should -BeExactly $null
            Get-IBConfig 'prof2'       | Should -BeExactly $null

            # make sure what's left on disk is correct
            $fakeConfigFile | Should -Not -Exist
        }
    }
}
