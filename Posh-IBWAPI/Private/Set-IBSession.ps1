function Set-IBSession {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [uri]$Uri,
        [Parameter(Mandatory)]
        [pscredential]$Credential,
        [Parameter(Mandatory)]
        [Microsoft.PowerShell.Commands.WebRequestSession]$WebSession
    )

    $script:Sessions."$($Uri.Authority)|$($Credential.Username)" = $WebSession
}
