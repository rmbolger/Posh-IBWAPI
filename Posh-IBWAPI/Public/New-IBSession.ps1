function New-IBSession
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true,Position=0)]
        [Alias('host')]
        [string]$WAPIHost,
        [Parameter(Mandatory=$true,Position=1)]
        [PSCredential]$Credential,
        [switch]$SkipCertificateCheck
    )

    # There's no explicit logon endpoint in the WAPI, so we're just going to
    # call the oldest backward compatible endpoint which should should
    # be sufficiently generic as to work on pretty much any NIOS endpoint. The
    # oldest WAPI docs I could find were for 1.1. So we're gonna go with this
    # until someone comes along who has a problem with an ancient 1.0 based
    # NIOS install.

    Invoke-IBWAPI -uri "https://$WAPIHost/wapi/v1.1/member" -cred $Credential -SessionVariable ibsession -SkipCertificateCheck:$SkipCertificateCheck | Out-Null

    Write-Output $ibsession




    <#
    .SYNOPSIS
        Create a session object that can be used for subsequent commands.

    .DESCRIPTION
        This command calls a generic WAPI endpoint in order to login and generate an authentication cookie that can be used for subsequent requests. It is returned as a WebRequestSession object.

    .PARAMETER WAPIHost
        The fully qualified DNS name or IP address of the Infoblox WAPI endpoint (usually the grid master).

    .PARAMETER Credential
        Username and password for the Infoblox appliance.

    .PARAMETER SkipCertificateCheck
        If set, SSL/TLS certificate validation will be disabled.

    .OUTPUTS
        Microsoft.PowerShell.Commands.WebRequestSession. This object can be used with other commands with the -WebSession parameter.

    .EXAMPLE
        $session = Get-IBSession -WAPIHost 'gridmaster.example.com' -Credential (Get-Credential)

        Open a session for the specified grid master and using interactive credentials.

    .LINK
        Project: https://github.com/rmbolger/Posh-IBWAPI

    .LINK
        Invoke-IBWAPI

    .LINK
        Get-IBObject

    #>
}
