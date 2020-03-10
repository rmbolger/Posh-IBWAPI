function Test-NonEmptyString {
    [CmdletBinding()]
    param(
        [Parameter(Position=0)]
        [string]$Value,
        [switch]$ThrowOnFail
    )

    if ([String]::IsNullOrWhiteSpace($Value)) {
        if ($ThrowOnFail) {
            throw [Management.Automation.ValidationMetadataException] "Value must not be null, empty, or only whitespace."
        }
        return $false
    }

    return $true
}
