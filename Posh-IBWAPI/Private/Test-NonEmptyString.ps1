function Test-NonEmptyString {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true,Position=0)]
        [string]$Value,
        [switch]$ThrowOnFail
    )

    if ([String]::IsNullOrWhiteSpace($Value)) {
        if ($ThrowOnFail) {
            throw [Management.Automation.ValidationMetadataException] "Value must not be empty or whitespace."
        }
        return $false
    }

    return $true
}
