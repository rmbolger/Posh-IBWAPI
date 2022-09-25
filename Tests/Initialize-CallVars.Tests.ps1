Describe "Initialize-CallVars" {

    # setup fake credentials for test cases
    $pass1 = ConvertTo-SecureString 'pass1' -AsPlainText -Force
    $cred1 = New-Object PSCredential 'admin1',$pass1
    $pass2 = ConvertTo-SecureString 'pass2' -AsPlainText -Force
    $cred2 = New-Object PSCredential 'admin2',$pass2
    $pass3 = ConvertTo-SecureString 'pass3' -AsPlainText -Force
    $cred3 = New-Object PSCredential 'admin3',$pass2

    BeforeAll {
        $env:LOCALAPPDATA = 'TestDrive:\'
        $env:HOME = 'TestDrive:\'
        Import-Module (Join-Path $PSScriptRoot '..\Posh-IBWAPI\Posh-IBWAPI.psd1')

        # setup fake profiles for mocking with
        $pass1 = ConvertTo-SecureString 'pass1' -AsPlainText -Force
        $cred1 = New-Object PSCredential 'admin1',$pass1
        $prof1 = @{
            WAPIHost = 'gm1'
            WAPIVersion = '1.0'
            Credential = $cred1
            SkipCertificateCheck = $false
        }
        $pass2 = ConvertTo-SecureString 'pass2' -AsPlainText -Force
        $cred2 = New-Object PSCredential 'admin2',$pass2
        $prof2 = @{
            WAPIHost = 'gm2'
            WAPIVersion = '2.0'
            Credential = $cred2
            SkipCertificateCheck = $true
        }
    }

    Context "No profiles" {

        BeforeAll {
            Mock -ModuleName Posh-IBWAPI Get-Profiles { return @{} }
            Mock -ModuleName Posh-IBWAPI Get-CurrentProfile { return [string]::Empty }
        }

        It "Throws if mandatory params are missing" -TestCases @(
            @{ splat = @{ WAPIVersion='2.0'; Credential=$cred2 } }
            @{ splat = @{ WAPIHost='gm2'; Credential=$cred2 } }
            @{ splat = @{ WAPIHost='gm2'; WAPIVersion='2.0' } }
        ) {
            InModuleScope Posh-IBWAPI -Parameters @{Splat=$splat} {
                param ($Splat)
                { Initialize-CallVars @Splat } | Should -Throw
            }
        }

        It "Succeeds with minimum params" -TestCases @(
            @{ splat = @{ WAPIHost='gm2'; WAPIVersion='2.0'; Credential=$cred2 } }
            @{ splat = @{ WAPIHost='gm2'; WAPIVersion='2.0'; Credential=$cred2; SkipCertificateCheck=$true } }
            @{ splat = @{ WAPIHost='gm2'; WAPIVersion='2.0'; Credential=$cred2; SkipCertificateCheck=$false } }
            @{ splat = @{ WAPIHost='gm2'; WAPIVersion='2.0'; Credential=$cred2; ProfileName='noexist' } }
        ) {
            InModuleScope Posh-IBWAPI -Parameters @{Splat=$splat} {
                param($Splat)

                { Initialize-CallVars @Splat } | Should -Not -Throw
                $result = Initialize-CallVars @Splat
                $result.WAPIHost               | Should -Be $Splat.WAPIHost
                $result.WAPIVersion            | Should -Be $Splat.WAPIVersion
                $result.Credential.Username    | Should -Be $Splat.Credential.Username
                $result.SkipCertificateCheck   | Should -Be $Splat.SkipCertificateCheck
            }
        }
    }

    Context "1 profile" {

        BeforeAll {
            Mock -ModuleName Posh-IBWAPI Get-Profiles { return @{ 'prof1' = $prof1 } }
            Mock -ModuleName Posh-IBWAPI Get-CurrentProfile { return 'prof1' }
        }

        It "Throws if mandatory params are missing and bad ProfileName" -TestCases @(
            @{ splat = @{ WAPIVersion='2.0'; Credential=$cred2; ProfileName='noexist' } }
            @{ splat = @{ WAPIHost='gm2'; Credential=$cred2; ProfileName='noexist' } }
            @{ splat = @{ WAPIHost='gm2'; WAPIVersion='2.0'; ProfileName='noexist' } }
        ) {
            InModuleScope Posh-IBWAPI -Parameters @{Splat=$splat} {
                param ($Splat)
                { Initialize-CallVars @Splat } | Should -Throw
            }
        }

        It "Succeeds with min params and bad ProfileName" -TestCases @(
            @{ splat = @{ WAPIHost='gm2'; WAPIVersion='2.0'; Credential=$cred2; ProfileName='noexist' } }
            @{ splat = @{ WAPIHost='gm2'; WAPIVersion='2.0'; Credential=$cred2; SkipCertificateCheck=$true; ProfileName='noexist' } }
            @{ splat = @{ WAPIHost='gm2'; WAPIVersion='2.0'; Credential=$cred2; SkipCertificateCheck=$false; ProfileName='noexist' } }
        ) {
            InModuleScope Posh-IBWAPI -Parameters @{Splat=$splat} {
                param ($Splat)
                { Initialize-CallVars @Splat } | Should -Not -Throw
                $result = Initialize-CallVars @Splat
                $result.WAPIHost               | Should -Be $Splat.WAPIHost
                $result.WAPIVersion            | Should -Be $Splat.WAPIVersion
                $result.Credential.Username    | Should -Be $Splat.Credential.Username
                $result.SkipCertificateCheck   | Should -Be $Splat.SkipCertificateCheck
            }
        }

        It "Succeeds with no ProfileName" -TestCases @(
            @{ splat = @{ } }
            @{ splat = @{ WAPIHost='gm2' } }
            @{ splat = @{ WAPIVersion='2.0' } }
            @{ splat = @{ Credential=$cred2 } }
            @{ splat = @{ SkipCertificateCheck = $true } }
        ) {
            InModuleScope Posh-IBWAPI -Parameters @{Splat=$splat} {
                param($Splat)

                { Initialize-CallVars @Splat } | Should -Not -Throw
                $result = Initialize-CallVars @Splat

                # anything we passed should override the profile defaults
                $Splat.GetEnumerator() | ForEach-Object {
                    $result.($_.Key) | Should -Be $Splat.($_.Key)
                }

                # anything we didn't pass should use profile default
                if ('WAPIHost' -notin $Splat.Keys) {
                    $result.WAPIHost | Should -Be 'gm1'
                }
                if ('WAPIVersion' -notin $Splat.Keys) {
                    $result.WAPIVersion | Should -Be '1.0'
                }
                if ('Credential' -notin $Splat.Keys) {
                    $result.Credential.Username | Should -Be 'admin1'
                }
                if ('SkipCertificateCheck' -notin $Splat.Keys) {
                    $result.SkipCertificateCheck | Should -BeFalse
                }
            }
        }
    }

    Context "2 profiles" {

        BeforeAll {
            Mock -ModuleName Posh-IBWAPI Get-Profiles { return @{ 'prof1'=$prof1; 'prof2'=$prof2 } }
            Mock -ModuleName Posh-IBWAPI Get-CurrentProfile { return 'prof1' }
        }

        It "Explicit profile overrides active profile" -TestCases @(
            @{ splat = @{ ProfileName='prof2' } }
            @{ splat = @{ WAPIHost='gm3'; ProfileName='prof2' } }
            @{ splat = @{ WAPIVersion='3.0'; ProfileName='prof2' } }
            @{ splat = @{ Credential=$cred3; ProfileName='prof2' } }
            @{ splat = @{ SkipCertificateCheck=$false; ProfileName='prof2' } }
        ) {
            InModuleScope Posh-IBWAPI -Parameters @{Splat=$splat} {
                param ($Splat)
                { Initialize-CallVars @Splat } | Should -Not -Throw
                $result = Initialize-CallVars @Splat

                # anything we passed should override the profile defaults
                $Splat.GetEnumerator() | Where-Object { $_.Key -ne 'ProfileName' } | ForEach-Object {
                    $result.($_.Key) | Should -Be $Splat.($_.Key)
                }

                # anything we didn't pass should use explicit profile default
                if ('WAPIHost' -notin $Splat.Keys) {
                    $result.WAPIHost | Should -Be 'gm2'
                }
                if ('WAPIVersion' -notin $Splat.Keys) {
                    $result.WAPIVersion | Should -Be '2.0'
                }
                if ('Credential' -notin $Splat.Keys) {
                    $result.Credential.Username | Should -Be 'admin2'
                }
                if ('SkipCertificateCheck' -notin $Splat.Keys) {
                    $result.SkipCertificateCheck | Should -BeTrue
                }
            }
        }

    }


}
