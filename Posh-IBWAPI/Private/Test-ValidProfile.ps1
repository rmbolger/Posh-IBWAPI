function Test-ValidProfile {
    [CmdletBinding()]
    param(
        [Parameter(Position=0)]
        [string]$Value,
        [switch]$ThrowOnFail
    )

    if ($Value -notin (Get-IBConfig -List).ProfileName) {
        if ($ThrowOnFail) {
            throw [Management.Automation.ValidationMetadataException] "Value is not a valid profile name."
        }
        return $false
    }

    return $true
}
