function Get-CurrentProfile {
    [CmdletBinding()]
    param()

    # this is largely a wrapper to enable easier mocking
    return $script:CurrentProfile
}
