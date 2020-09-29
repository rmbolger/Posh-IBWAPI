BeforeAll {
    Import-Module (Join-Path $PSScriptRoot '..\Posh-IBWAPI\Posh-IBWAPI.psd1')

    # setup fake profile export location
    $fakeConfigFolder = 'TestDrive:\config'
    $fakeConfigFile   = 'TestDrive:\config\posh-ibwapi.json'
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

}
