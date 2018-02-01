Import-Module Posh-IBWAPI

Describe "Posh-IBWAPI module loader" {
    InModuleScope Posh-IBWAPI {

        # $script:ConfigFolder
        It "`$script:ConfigFolder is String" {
            $script:ConfigFolder | Should -BeOfType String
        }
        It "`$script:ConfigFolder not null or empty" {
            $script:ConfigFolder | Should -Not -BeNullOrEmpty
        }

        # $script:ConfigFile
        It "`$script:ConfigFile is String" {
            $script:ConfigFile | Should -BeOfType String
        }
        It "`$script:ConfigFile ends with posh-ibwapi.json" {
            $script:ConfigFile | Should -BeLike '*posh-ibwapi.json'
            # BeLikeExactly broken until 4.2
            #$script:ConfigFile | Should -BeLikeExactly '*posh-ibwapi.json'
        }

        # $script:APIBaseTemplate
        It "`$script:APIBaseTemplate is String" {
            $script:APIBaseTemplate | Should -BeOfType String
        }
        It "`$script:APIBaseTemplate not null or empty" {
            $script:APIBaseTemplate | Should -Not -BeNullOrEmpty
        }
        # $script:WAPIDocTemplate
        It "`$script:WAPIDocTemplate is String" {
            $script:WAPIDocTemplate | Should -BeOfType String
        }
        It "`$script:WAPIDocTemplate not null or empty" {
            $script:WAPIDocTemplate | Should -Not -BeNullOrEmpty
        }

        # $script:CurrentHost
        It "`$script:CurrentHost is String" {
            $script:CurrentHost | Should -BeOfType String
        }
        It "`$script:CurrentHost not null" {
            $script:CurrentHost | Should -Not -Be $null
        }

        # $script:Config
        It "`$script:Config is hashtable" {
            $script:Config | Should -BeOfType hashtable
        }

    }
}