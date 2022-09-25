Describe "Get-IBObject" {

    BeforeAll {
        $env:LOCALAPPDATA = 'TestDrive:\'
        $env:HOME = 'TestDrive:\'
        Import-Module (Join-Path $PSScriptRoot '..\Posh-IBWAPI\Posh-IBWAPI.psd1')

        $pass1 = ConvertTo-SecureString 'pass1' -AsPlainText -Force
        $cred1 = New-Object PSCredential 'admin1',$pass1

        Mock Initialize-CallVars -ModuleName Posh-IBWAPI { return @{
            WAPIHost = 'gm1'
            WAPIVersion = '2.11.1'
            Credential = $cred1
            SkipCertificateCheck = $true
        }}
    }

    Context "Return Fields" {

        BeforeAll {
            Mock Invoke-IBWAPI -ModuleName Posh-IBWAPI { [pscustomobject]@{ result = @(
                [pscustomobject]@{'_ref' = 'fake/12345:Infoblox'}
            )}}
            # fake schema results
            Mock Get-IBSchema -ModuleName Posh-IBWAPI { [pscustomobject]@{ fields = @(
                [pscustomobject]@{ name='d'; supports='r' }
                [pscustomobject]@{ name='e'; supports='r' }
                [pscustomobject]@{ name='f'; supports='r' }
            )}}
            Mock Get-ReadFieldsForType -ModuleName Posh-IBWAPI { @('d','e','f') }
        }

        It "Won't ask for return fields when not specified" -TestCases @(
            @{ splat=@{ ObjectRef='fake/12345:Infoblox' } }
            @{ splat=@{ ObjectRef='fake/12345:Infoblox'; ReturnBaseFields=$true } }
            @{ splat=@{ ObjectRef='fake/12345:Infoblox'; ProxySearch=$true } }
            @{ splat=@{ ObjectType='fake' } }
            @{ splat=@{ ObjectType='fake'; ReturnBaseFields=$true } }
            @{ splat=@{ ObjectType='fake'; ProxySearch=$true } }
            @{ splat=@{ ObjectType='fake'; Filter='flt1=foo' } }
            @{ splat=@{ ObjectType='fake'; Filter='flt1=foo','flt2=bar' } }
            @{ splat=@{ ObjectType='fake'; MaxResults=10 } }
            @{ splat=@{ ObjectType='fake'; MaxResults=-10 } }
            @{ splat=@{ ObjectType='fake'; PageSize=10 } }
            @{ splat=@{ ObjectType='fake'; NoPaging=$true } }
        ) {
            Get-IBObject @splat | Out-Null
            Should -Invoke Invoke-IBWAPI -ModuleName Posh-IBWAPI -ParameterFilter {
                $Uri.OriginalString -notlike '*_return_fields*'
            }
        }

        It "Asks for return fields when specified" -TestCases @(
            @{ splat=@{ ObjectRef='fake/12345:Infoblox'; ReturnFields='a' } }
            @{ splat=@{ ObjectRef='fake/12345:Infoblox'; ReturnFields='a','b','c' } }
            @{ splat=@{ ObjectRef='fake/12345:Infoblox'; ReturnFields='a'; ReturnBaseFields=$true } }
            @{ splat=@{ ObjectRef='fake/12345:Infoblox'; ReturnFields='a','b','c'; ReturnBaseFields=$true } }
            @{ splat=@{ ObjectType='fake'; ReturnFields='a' } }
            @{ splat=@{ ObjectType='fake'; ReturnFields='a','b','c' } }
            @{ splat=@{ ObjectType='fake'; ReturnFields='a'; ReturnBaseFields=$true } }
            @{ splat=@{ ObjectType='fake'; ReturnFields='a','b','c'; ReturnBaseFields=$true } }
        ) {
            Get-IBObject @splat | Out-Null

            if ($splat.ReturnBaseFields -eq $true) {
                $check += "_return_fields%2B=$($splat.ReturnFields -join ',')"
            } else {
                $check += "_return_fields=$($splat.ReturnFields -join ',')"
            }

            Should -Invoke Invoke-IBWAPI -ModuleName Posh-IBWAPI -ParameterFilter {
                $Uri.OriginalString -like "*$check*"
            }
        }

        It "Asks for all fields when specified" -TestCases @(
            @{ splat=@{ ObjectRef='fake/12345:Infoblox'; ReturnAllFields=$true } }
            @{ splat=@{ ObjectRef='fake/12345:Infoblox'; ReturnFields='a','b','c'; ReturnAllFields=$true } }
            @{ splat=@{ ObjectRef='fake/12345:Infoblox'; ReturnFields='a','b','c'; ReturnBaseFields=$true; ReturnAllFields=$true } }
            @{ splat=@{ ObjectType='fake'; ReturnAllFields=$true } }
            @{ splat=@{ ObjectType='fake'; ReturnFields='a','b','c'; ReturnAllFields=$true } }
            @{ splat=@{ ObjectType='fake'; ReturnFields='a','b','c'; ReturnBaseFields=$true; ReturnAllFields=$true } }
        ) {
            Get-IBObject @splat | Out-Null

            Should -Invoke Get-IBSchema -ModuleName Posh-IBWAPI
            Should -Invoke Invoke-IBWAPI -ModuleName Posh-IBWAPI -ParameterFilter {
                $Uri.OriginalString -like "*_return_fields=d,e,f*"
            }
        }
    }

    Context "Filter" {

        BeforeAll {
            Mock Invoke-IBWAPI -ModuleName Posh-IBWAPI { [pscustomobject]@{ result = @(
                [pscustomobject]@{'_ref' = 'fake/12345:Infoblox'}
            )}}
        }

        It "Asks for specified filters" -TestCases @(
            @{ splat=@{ ObjectType='fake'; Filter='arg1=foo' } }
            @{ splat=@{ ObjectType='fake'; Filter='arg1!=foo' } }
            @{ splat=@{ ObjectType='fake'; Filter='arg1~=foo' } }
            @{ splat=@{ ObjectType='fake'; Filter='arg1<=foo' } }
            @{ splat=@{ ObjectType='fake'; Filter='arg1>=foo' } }
            @{ splat=@{ ObjectType='fake'; Filter='arg1=foo','arg2=bar' } }
        ) {
            Get-IBObject @splat | Out-Null

            Should -Invoke Invoke-IBWAPI -ModuleName Posh-IBWAPI -ParameterFilter {
                $Uri.OriginalString -like "*$($splat.Filter -join '&')*"
            }
        }
    }

    Context "Paging" {

        It "Throws when MaxResults/PageSize out of bounds" {
            Mock Invoke-IBWAPI -ModuleName Posh-IBWAPI { [pscustomobject]@{ result = @(
                [pscustomobject]@{'_ref' = 'fake/12345:Infoblox'}
            )}}

            { Get-IBObject fake -MaxResults -2147483648 } | Should -Throw
            { Get-IBObject fake -MaxResults -2147483647 } | Should -Not -Throw
            { Get-IBObject fake -MaxResults 2147483647 } | Should -Not -Throw
            { Get-IBObject fake -MaxResults 2147483648 } | Should -Throw
            { Get-IBObject fake -PageSize 0 }    | Should -Throw
            { Get-IBObject fake -PageSize 1 }    | Should -Not -Throw
            { Get-IBObject fake -PageSize 1000 } | Should -Not -Throw
            { Get-IBObject fake -PageSize 1001 } | Should -Throw
        }

        It "Sets page size appropriately" {
            Mock Invoke-IBWAPI -ModuleName Posh-IBWAPI { [pscustomobject]@{ result = @(
                [pscustomobject]@{'_ref' = 'fake/12345:Infoblox'}
            )}}

            # default 1000
            Get-IBObject fake | Out-Null
            Should -Invoke Invoke-IBWAPI -ModuleName Posh-IBWAPI -ParameterFilter { $Uri.OriginalString -like '*_max_results=1000' }

            # explicit PageSize
            Get-IBObject fake -PageSize 100 | Out-Null
            Should -Invoke Invoke-IBWAPI -ModuleName Posh-IBWAPI -ParameterFilter { $Uri.OriginalString -like '*_max_results=100' }

            # PageSize = MaxResults + 1 (up to 1000) when less than default/explicit page size
            Get-IBObject fake -MaxResults 100 | Out-Null
            Should -Invoke Invoke-IBWAPI -ModuleName Posh-IBWAPI -ParameterFilter { $Uri.OriginalString -like '*_max_results=101' }
            Get-IBObject fake -MaxResults -100 | Out-Null
            Should -Invoke Invoke-IBWAPI -ModuleName Posh-IBWAPI -ParameterFilter { $Uri.OriginalString -like '*_max_results=101' }
            Get-IBObject fake -MaxResults 999 | Out-Null
            Should -Invoke Invoke-IBWAPI -ModuleName Posh-IBWAPI -ParameterFilter { $Uri.OriginalString -like '*_max_results=1000' }
            Get-IBObject fake -MaxResults -999 | Out-Null
            Should -Invoke Invoke-IBWAPI -ModuleName Posh-IBWAPI -ParameterFilter { $Uri.OriginalString -like '*_max_results=1000' }
            Get-IBObject fake -MaxResults 999999 | Out-Null
            Should -Invoke Invoke-IBWAPI -ModuleName Posh-IBWAPI -ParameterFilter { $Uri.OriginalString -like '*_max_results=1000' }
            Get-IBObject fake -MaxResults -999999 | Out-Null
            Should -Invoke Invoke-IBWAPI -ModuleName Posh-IBWAPI -ParameterFilter { $Uri.OriginalString -like '*_max_results=1000' }
            Get-IBObject fake -MaxResults 100 -PageSize 50 | Out-Null
            Should -Invoke Invoke-IBWAPI -ModuleName Posh-IBWAPI -ParameterFilter { $Uri.OriginalString -like '*_max_results=50' }
            Get-IBObject fake -MaxResults -100 -PageSize 50 | Out-Null
            Should -Invoke Invoke-IBWAPI -ModuleName Posh-IBWAPI -ParameterFilter { $Uri.OriginalString -like '*_max_results=50' }
            Get-IBObject fake -MaxResults 100 -PageSize 200 | Out-Null
            Should -Invoke Invoke-IBWAPI -ModuleName Posh-IBWAPI -ParameterFilter { $Uri.OriginalString -like '*_max_results=101' }
            Get-IBObject fake -MaxResults -100 -PageSize 200 | Out-Null
            Should -Invoke Invoke-IBWAPI -ModuleName Posh-IBWAPI -ParameterFilter { $Uri.OriginalString -like '*_max_results=101' }
        }


        It "Disables paging for WAPIVersion < 1.5" {
            Mock Initialize-CallVars -ModuleName Posh-IBWAPI { return @{
                WAPIHost = 'gm1'
                WAPIVersion = '1.4'
                Credential = $cred1
                SkipCertificateCheck = $false
            }}
            Mock Invoke-IBWAPI -ModuleName Posh-IBWAPI { }

            Get-IBObject fake | Out-Null
            Should -Invoke Invoke-IBWAPI -ModuleName Posh-IBWAPI -ParameterFilter {
                $Uri.OriginalString -notlike '*_paging=1*'
            }
        }

        It "Disables paging with -NoPaging" {
            Mock Invoke-IBWAPI -ModuleName Posh-IBWAPI { }

            Get-IBObject fake -NoPaging | Out-Null
            Should -Invoke Invoke-IBWAPI -ModuleName Posh-IBWAPI -ParameterFilter {
                $Uri.OriginalString -notlike '*_paging=1*'
            }
        }

        It "Retrieves all pages" {
            Mock Invoke-IBWAPI -ModuleName Posh-IBWAPI -ParameterFilter { $Uri.OriginalString -like "*_paging=1*" } -MockWith {
                [pscustomobject]@{
                    result = @( [pscustomobject]@{'_ref' = 'fake/12345:Infoblox'} )
                    next_page_id = '2'
                }
            }
            Mock Invoke-IBWAPI -ModuleName Posh-IBWAPI -ParameterFilter { $Uri.OriginalString -like "*_page_id=2*" } -MockWith {
                [pscustomobject]@{
                    result = @( [pscustomobject]@{'_ref' = 'fake/23456:Infoblox'} )
                    next_page_id = '3'
                }
            }
            Mock Invoke-IBWAPI -ModuleName Posh-IBWAPI -ParameterFilter { $Uri.OriginalString -like "*_page_id=3*" } -MockWith {
                [pscustomobject]@{
                    result = @( [pscustomobject]@{'_ref' = 'fake/34567:Infoblox'} )
                }
            }

            Get-IBObject fake | Out-Null
            Should -Invoke Invoke-IBWAPI -ModuleName Posh-IBWAPI -Exactly 3
        }
    }

    Context "MaxResults" {

        It "Has no effect when Abs(MaxResults) > result count" {
            Mock Invoke-IBWAPI -ModuleName Posh-IBWAPI {
                [pscustomobject]@{
                    result = @(
                        [pscustomobject]@{'_ref' = 'fake/12345:Infoblox'}
                        [pscustomobject]@{'_ref' = 'fake/23456:Infoblox'}
                        [pscustomobject]@{'_ref' = 'fake/34567:Infoblox'}
                    )
                }
            }

            { Get-IBObject fake -MaxResults 5 } | Should -Not -Throw
            $results = Get-IBObject fake -MaxResults 5
            $results | Should -HaveCount 3

            { Get-IBObject fake -MaxResults -5 } | Should -Not -Throw
            $results = Get-IBObject fake -MaxResults -5
            $results | Should -HaveCount 3
        }

        It "Limits results when MaxResults positive" {
            Mock Invoke-IBWAPI -ModuleName Posh-IBWAPI {
                [pscustomobject]@{
                    result = @(
                        [pscustomobject]@{'_ref' = 'fake/12345:Infoblox'}
                        [pscustomobject]@{'_ref' = 'fake/23456:Infoblox'}
                        [pscustomobject]@{'_ref' = 'fake/34567:Infoblox'}
                        [pscustomobject]@{'_ref' = 'fake/45678:Infoblox'}
                        [pscustomobject]@{'_ref' = 'fake/56789:Infoblox'}
                        [pscustomobject]@{'_ref' = 'fake/6789A:Infoblox'}
                        [pscustomobject]@{'_ref' = 'fake/789AB:Infoblox'}
                    )
                }
            }

            { Get-IBObject fake -MaxResults 4 } | Should -Not -Throw
            $results = Get-IBObject fake -MaxResults 4
            $results | Should -HaveCount 4

            { Get-IBObject fake -MaxResults 5 } | Should -Not -Throw
            $results = Get-IBObject fake -MaxResults 5
            $results | Should -HaveCount 5
        }

        It "Throws when MaxResults negative" {
            Mock Invoke-IBWAPI -ModuleName Posh-IBWAPI {
                [pscustomobject]@{
                    result = @(
                        [pscustomobject]@{'_ref' = 'fake/12345:Infoblox'}
                        [pscustomobject]@{'_ref' = 'fake/23456:Infoblox'}
                        [pscustomobject]@{'_ref' = 'fake/34567:Infoblox'}
                        [pscustomobject]@{'_ref' = 'fake/45678:Infoblox'}
                        [pscustomobject]@{'_ref' = 'fake/56789:Infoblox'}
                        [pscustomobject]@{'_ref' = 'fake/6789A:Infoblox'}
                        [pscustomobject]@{'_ref' = 'fake/789AB:Infoblox'}
                    )
                }
            }

            { Get-IBObject fake -MaxResults -4 } | Should -Throw

            { Get-IBObject fake -MaxResults -5 } | Should -Throw
        }

    }

    Context "Misc" {

        It "Uses ProxySearch" {
            Mock Invoke-IBWAPI -ModuleName Posh-IBWAPI { [pscustomobject]@{ result = @(
                [pscustomobject]@{'_ref' = 'fake/12345:Infoblox'}
            )}}

            Get-IBObject fake -ProxySearch | Out-Null
            Should -Invoke Invoke-IBWAPI -ModuleName Posh-IBWAPI -ParameterFilter {
                $Uri.OriginalString -like '*_proxy_search=GM*'
            }
        }

        It "Passes Credential and SkipCertificateCheck" {
            Mock Invoke-IBWAPI -ModuleName Posh-IBWAPI { [pscustomobject]@{ result = @(
                [pscustomobject]@{'_ref' = 'fake/12345:Infoblox'}
            )}}

            Get-IBObject fake | Out-Null
            Should -Invoke Invoke-IBWAPI -ModuleName Posh-IBWAPI -ParameterFilter {
                $Credential.Username -eq 'admin1' -and
                $SkipCertificateCheck.IsPresent -eq $true
            }
        }
    }

}
