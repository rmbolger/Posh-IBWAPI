function Get-IBSession {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [uri]$Uri,
        [Parameter(Mandatory)]
        [pscredential]$Credential
    )

    $script:Sessions."$($Uri.Authority)|$($Credential.Username)"
}
