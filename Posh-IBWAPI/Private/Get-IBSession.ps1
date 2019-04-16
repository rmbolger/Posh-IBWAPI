function Get-IBSession {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [uri]$Uri,
        [Parameter(Mandatory=$true)]
        [pscredential]$Credential
    )

    $script:Sessions."$($Uri.Authority)|$($Credential.Username)"
}
