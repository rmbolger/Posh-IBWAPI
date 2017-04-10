function Get-IBSession
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true,Position=0)]
        [string]$ApiHost,
        [Parameter(Mandatory=$true,Position=1)]
        [PSCredential]$Credential
    )

    # There's no explicit logon endpoint in the WAPI, so we're just going to
    # call the oldest backward compatible schema endpoint which should should
    # be sufficiently generic as to work on pretty much any NIOS endpoint.

    Invoke-IBWAPI -uri "https://$ApiHost/wapi/v1.0/?_schema" -cred $Credential -SessionVariable ibsession | Out-Null

    Write-Output $ibsession




    <#
    .SYNOPSIS
        Get a session object that can be used for subsequent commands. I

    .DESCRIPTION
        This command calls a generic WAPI endpoint in order to login and generate an authentication cookie that can be used for subsequent requests. It is returned as a WebRequestSession object.

    .PARAMETER ApiHost
        The IP address or FQDN of the Infoblox WAPI host (usually the grid master).

    .PARAMETER Credential
        Username and password for the Infoblox appliance.

    .OUTPUTS
        Microsoft.PowerShell.Commands.WebRequestSession. This object can be used with other commands with the -WebSession parameter.

    .EXAMPLE
        $session = Get-IBSession -ApiHost 'gridmaster.example.com' -Credential (Get-Credential)

        Open a session for the specified grid master and using credentials gathered interactively at run time.

    .LINK
        Project: https://github.com/rmbolger/Posh-IBWAPI

    .LINK
        Invoke-IBWAPI

    .LINK
        Get-IBObject

    #>
}