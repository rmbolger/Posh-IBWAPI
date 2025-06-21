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
                Select-Object @{L='ProfileName';E={$profName}},WAPIHost,WAPIVersion,Credential,SkipCertificateCheck,NoSession
            $p.PSObject.TypeNames.Insert(0,'PoshIBWAPI.IBConfig')
            return $p

        } else {

            # return the selected profile if it exists
            if ($ProfileName -in $profiles.Keys) {
                $p = [PSCustomObject]$profiles.$ProfileName |
                    Select-Object @{L='ProfileName';E={$ProfileName}},WAPIHost,WAPIVersion,Credential,SkipCertificateCheck,NoSession
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
                Select-Object @{L='ProfileName';E={$profName}},WAPIHost,WAPIVersion,Credential,SkipCertificateCheck,NoSession
            $p.PSObject.TypeNames.Insert(0,'PoshIBWAPI.IBConfig')
            Write-Output $p
        }

    }
}
