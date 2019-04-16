function Set-IBSession {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [uri]$Uri,
        [Parameter(Mandatory=$true)]
        [pscredential]$Credential,
        [Parameter(Mandatory=$true)]
        [Microsoft.PowerShell.Commands.WebRequestSession]$WebSession
    )

    $script:Sessions."$($Uri.Authority)|$($Credential.Username)" = $WebSession
}
