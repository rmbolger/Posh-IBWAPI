Describe "Set-IBConfig" {

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

        # setup fake credentials to use
        $fakePass1 = ConvertTo-SecureString 'password1' -AsPlainText -Force
        $fakeCred1 = New-Object PSCredential 'admin1',$fakePass1
        $fakePass2 = ConvertTo-SecureString 'password2' -AsPlainText -Force
        $fakeCred2 = New-Object PSCredential 'admin2',$fakePass2

        Mock -ModuleName Posh-IBWAPI Get-ConfigFolder { $fakeConfigFolder }
        Mock -ModuleName Posh-IBWAPI Get-ConfigFile { $fakeConfigFile }
        Mock -ModuleName Posh-IBWAPI HighestVer { '99' }
    }

    BeforeEach {
        InModuleScope Posh-IBWAPI { Import-IBConfig }
    }

    It "Enforces mandatory parameters on new profiles" {

        # missing ProfileName
        { Set-IBConfig                      -WAPIHost 'gm1' -WAPIVersion '1.0' -Credential $fakeCred1 } | Should -Throw
        # missing WAPIHost
        { Set-IBConfig -ProfileName 'prof1'                 -WAPIVersion '1.0' -Credential $fakeCred1 } | Should -Throw
        # missing WAPIVersion
        { Set-IBConfig -ProfileName 'prof1' -WAPIHost 'gm1'                    -Credential $fakeCred1 } | Should -Throw
        # missing Credential
        { Set-IBConfig -ProfileName 'prof1' -WAPIHost 'gm1' -WAPIVersion '1.0'                        } | Should -Throw
    }

    It "Writes correct profile with minimum values specified" {

        Set-IBConfig -ProfileName 'prof1' -WAPIHost 'gm1' -WAPIVersion '1.0' -Credential $fakeCred1

        $fakeConfigFile | Should -Exist

        $config = Get-IBConfig
        $config                      | Should -Not -BeNullOrEmpty
        $config.PSTypeNames          | Should -Contain PoshIBWAPI.IBConfig
        $config.ProfileName          | Should -Be 'prof1'
        $config.WAPIHost             | Should -Be 'gm1'
        $config.WAPIVersion          | Should -Be '1.0'
        $config.Credential.Username  | Should -Be 'admin1'
        $config.SkipCertificateCheck | Should -BeFalse
    }

    It "Writes second profile with all values specified" {

        Set-IBConfig -ProfileName 'prof2' -WAPIHost 'gm2' -WAPIVersion '2.0' -Credential $fakeCred2 -SkipCertificateCheck

        # make sure active profile is the one we just set
        $config = Get-IBConfig
        $config                      | Should -Not -BeNullOrEmpty
        $config.PSTypeNames          | Should -Contain PoshIBWAPI.IBConfig
        $config.ProfileName          | Should -Be 'prof2'
        $config.WAPIHost             | Should -Be 'gm2'
        $config.WAPIVersion          | Should -Be '2.0'
        $config.Credential.Username  | Should -Be 'admin2'
        $config.SkipCertificateCheck | Should -BeTrue

        # make sure original profile still exists
        $config = Get-IBConfig -ProfileName 'prof1'
        $config                      | Should -Not -BeNullOrEmpty
        $config.PSTypeNames          | Should -Contain PoshIBWAPI.IBConfig
        $config.ProfileName          | Should -Be 'prof1'
        $config.WAPIHost             | Should -Be 'gm1'
        $config.WAPIVersion          | Should -Be '1.0'
        $config.Credential.Username  | Should -Be 'admin1'
        $config.SkipCertificateCheck | Should -BeFalse
    }

    It "It obeys NoSwitchProfile flag" {

        Set-IBConfig -ProfileName 'prof1' -WAPIVersion '1.1' -NoSwitchProfile

        # active profile should still be prof2
        $config = Get-IBConfig
        $config                      | Should -Not -BeNullOrEmpty
        $config.PSTypeNames          | Should -Contain PoshIBWAPI.IBConfig
        $config.ProfileName          | Should -Be 'prof2'
        $config.WAPIHost             | Should -Be 'gm2'
        $config.WAPIVersion          | Should -Be '2.0'
        $config.Credential.Username  | Should -Be 'admin2'
        $config.SkipCertificateCheck | Should -BeTrue

        # prof1 profile should have updated version
        $config = Get-IBConfig -ProfileName 'prof1'
        $config                      | Should -Not -BeNullOrEmpty
        $config.WAPIVersion          | Should -Be '1.1'
    }

    It "Can rename a profile and change a value" {

        Set-IBConfig -ProfileName 'prof1' -WAPIVersion '1.11' -NewName 'prof11'

        # prof11 should now be active
        $config = Get-IBConfig
        $config                      | Should -Not -BeNullOrEmpty
        $config.ProfileName          | Should -Be 'prof11'
        $config.WAPIVersion          | Should -Be '1.11'

        # prof1 should no longer exist
        Get-IBConfig -ProfileName 'prof1' | Should -BeExactly $null
    }

    It "Makes no changes with an active profile and no arguments" {

        Set-IBConfig

        # prof11 should still be active with same values
        $config = Get-IBConfig
        $config                      | Should -Not -BeNullOrEmpty
        $config.PSTypeNames          | Should -Contain PoshIBWAPI.IBConfig
        $config.ProfileName          | Should -Be 'prof11'
        $config.WAPIHost             | Should -Be 'gm1'
        $config.WAPIVersion          | Should -Be '1.11'
        $config.Credential.Username  | Should -Be 'admin1'
        $config.SkipCertificateCheck | Should -BeFalse
    }

    It "Can set individual value on the active profile" {

        Set-IBConfig -WAPIHost 'gm11'
        (Get-IBConfig).WAPIHost | Should -Be 'gm11'

        Set-IBConfig -WAPIVersion '1.111'
        (Get-IBConfig).WAPIVersion | Should -Be '1.111'

        Set-IBConfig -Credential $fakeCred2
        (Get-IBConfig).Credential.Username | Should -Be 'admin2'

        Set-IBConfig -SkipCertificateCheck
        (Get-IBConfig).SkipCertificateCheck | Should -BeTrue
    }

    It "Can use 'latest' for WAPIVersion" {

        Set-IBConfig -WAPIVersion latest
        (Get-IBConfig).WAPIVersion | Should -Be '99'
    }

}
