function Get-IBConfig
{
    [CmdletBinding(DefaultParameterSetName='Specific')]
    [OutputType('PoshIBWAPI.IBConfig')]
    param(
        [Parameter(ParameterSetName='Specific',Position=0)]
        [ValidateScript({Test-NonEmptyString $_ -ThrowOnFail})]
        [string]$ProfileName,
        [Parameter(ParameterSetName='List',Mandatory)]
        [switch]$List
    )

    if ('Specific' -eq $PSCmdlet.ParameterSetName) {

        if (-not $ProfileName) {

            # return the current profile
            $profName = Get-CurrentProfile
            $p = [PSCustomObject]$script:Profiles.$profName |
                Select-Object @{L='ProfileName';E={$profName}},WAPIHost,WAPIVersion,Credential,SkipCertificateCheck
            $p.PSObject.TypeNames.Insert(0,'PoshIBWAPI.IBConfig')
            return $p

        } else {

            # return the selected profile if it exists
            if ($ProfileName -in $script:Profiles.Keys) {
                $p = [PSCustomObject]$script:Profiles.$ProfileName |
                    Select-Object @{L='ProfileName';E={$ProfileName}},WAPIHost,WAPIVersion,Credential,SkipCertificateCheck
                $p.PSObject.TypeNames.Insert(0,'PoshIBWAPI.IBConfig')
                return $p
            } else {
                return $null
            }

        }

    } else {

        # list all configs
        foreach ($profName in ($script:Profiles.Keys | Sort-Object)) {
            $p = [PSCustomObject]$script:Profiles.$profName |
                Select-Object @{L='ProfileName';E={$profName}},WAPIHost,WAPIVersion,Credential,SkipCertificateCheck
            $p.PSObject.TypeNames.Insert(0,'PoshIBWAPI.IBConfig')
            Write-Output $p

        }

    }




    <#
    .SYNOPSIS
        Get the one or more configuration profiles.

    .DESCRIPTION
        When calling this function with no parameters, the currently active profile will be returned. These values will be used by related function calls to the Infoblox API unless they are overridden by the function's own parameters.

        When called with -ProfileName, the profile matching that name will be returned. When called with -List, all profiles will be returned.

    .PARAMETER ProfileName
        The name of the config profile to return.

    .PARAMETER List
        If set, list all config sets currently stored.

    .EXAMPLE
        Get-IBConfig

        Get the current config profile.

    .EXAMPLE
        Get-IBConfig -List

        Get all config profiles.

    .LINK
        Project: https://github.com/rmbolger/Posh-IBWAPI

    .LINK
        Set-IBConfig

    .LINK
        Get-IBObject

    #>
}
