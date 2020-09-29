function Import-IBCred {
    [CmdletBinding()]
    param(
        [PSObject]$importedCred,
        [string]$profileName
    )

    # If the config was exported on a non-Windows system, the password will
    # have been Base64 encoded instead of DPAPI encrypted and there will be
    # a 'IsBase64' property set to $true on the credential object.
    if ($importedCred.IsBase64) {
        try {
            $passPlain = [Text.Encoding]::Unicode.GetString(
                [Convert]::FromBase64String($importedCred.Password)
            )
        } catch {
            Write-Warning "Unable to convert Base64 Credential for $($profileName): $($_.Exception.Message)"
            return $null
        }
        New-Object PSCredential(
            $importedCred.Username,
            ($passPlain | ConvertTo-SecureString -AsPlainText -Force)
        )
    } else {
        # Try to convert the password back into a SecureString and into a PSCredential
        try {
            $secPass = $importedCred.Password | ConvertTo-SecureString -ErrorAction Stop
        } catch {
            Write-Warning "Unable to convert Credential for $($profileName): $($_.Exception.Message)"
            return $null
        }
        return (New-Object PSCredential($importedCred.Username,$secPass))
    }
}
