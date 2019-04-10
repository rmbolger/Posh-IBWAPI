function Test-VersionString {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true,Position=0)]
        [string]$Value,
        [switch]$AllowLatest,
        [switch]$ThrowOnFail
    )

    # conditionally allow the 'latest' string
    if ($AllowLatest -and $Value -eq 'latest') { return $true }

    if (-not ($Value -as [Version])) {
        if ($ThrowOnFail) {
            throw [Management.Automation.ValidationMetadataException] "Value must be a valid version string (1.0, 1.7.2, 2.5, etc)."
        }
        return $false
    }

    return $true
}
