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

    $profiles = Get-Profiles

    if ('Specific' -eq $PSCmdlet.ParameterSetName) {

        if (-not $ProfileName) {

            # return the current profile
            $profName = Get-CurrentProfile
            $p = [PSCustomObject]$profiles.$profName |
                Select-Object @{L='ProfileName';E={$profName}},WAPIHost,WAPIVersion,Credential,SkipCertificateCheck
            $p.PSObject.TypeNames.Insert(0,'PoshIBWAPI.IBConfig')
            return $p

        } else {

            # return the selected profile if it exists
            if ($ProfileName -in $profiles.Keys) {
                $p = [PSCustomObject]$profiles.$ProfileName |
                    Select-Object @{L='ProfileName';E={$ProfileName}},WAPIHost,WAPIVersion,Credential,SkipCertificateCheck
                $p.PSObject.TypeNames.Insert(0,'PoshIBWAPI.IBConfig')
                return $p
            } else {
                return $null
            }

        }

    } else {

        # list all configs
        foreach ($profName in ($profiles.Keys | Sort-Object)) {
            $p = [PSCustomObject]$profiles.$profName |
                Select-Object @{L='ProfileName';E={$profName}},WAPIHost,WAPIVersion,Credential,SkipCertificateCheck
            $p.PSObject.TypeNames.Insert(0,'PoshIBWAPI.IBConfig')
            Write-Output $p
        }

    }




    <#
    .SYNOPSIS
        Get one or more connection profiles.

    .DESCRIPTION
        When calling this function with no parameters, the currently active profile will be returned. These values will be used by related function calls to the Infoblox API unless they are overridden by the function's own parameters.

        When called with -ProfileName, the profile matching that name will be returned. When called with -List, all profiles will be returned.

    .PARAMETER ProfileName
        The name of the connection profile to return.

    .PARAMETER List
        If set, list all connection profiles currently stored.

    .EXAMPLE
        Get-IBConfig

        Get the current connection profile.

    .EXAMPLE
        Get-IBConfig -List

        Get all connection profiles.

    .LINK
        Project: https://github.com/rmbolger/Posh-IBWAPI

    .LINK
        Set-IBConfig

    .LINK
        Get-IBObject

    #>
}
