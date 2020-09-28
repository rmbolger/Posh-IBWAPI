# The functions in this file exist solely to allow
# easier mocking in Pester tests.

function Get-ConfigFolder {
    return $script:ConfigFolder
}

function Get-ConfigFile {
    return $script:ConfigFile
}

function Get-CurrentProfile {
    return $script:CurrentProfile
}

function Set-CurrentProfile {
    param(
        [Parameter(Mandatory)]
        [AllowEmptyString()]
        [string]$ProfileName
    )
    $script:CurrentProfile = $ProfileName
}

function Get-Profiles {
    return $script:Profiles
}
