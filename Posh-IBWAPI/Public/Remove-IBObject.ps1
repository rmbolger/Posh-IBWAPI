function Remove-IBObject
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$True)]
        [string]$ObjectRef,
        [string]$ComputerName,
        [string]$APIVersion,
        [PSCredential]$Credential,
        [Microsoft.PowerShell.Commands.WebRequestSession]$WebSession,
        [bool]$IgnoreCertificateValidation
    )

    # grab the variables we'll be using for our REST calls
    $common = $ComputerName,$APIVersion,$Credential,$WebSession
    if ($PSBoundParameters.ContainsKey('IgnoreCertificateValidation')) { $common += $IgnoreCertificateValidation }
    $cfg = Initialize-CallVars @common

    Invoke-IBWAPI -Method Delete -Uri "$($cfg.APIBase)$($ObjectRef)" -WebSession $cfg.WebSession -IgnoreCertificateValidation $cfg.IgnoreCertificateValidation




    <#
    .SYNOPSIS
        Delete an object from Infoblox.

    .DESCRIPTION
        Specify an object reference to delete that object from the Infoblox database.

    .PARAMETER ObjectRef
        Object reference string. This is usually found in the "_ref" field of returned objects.

    .PARAMETER ComputerName
        The fully qualified DNS name or IP address of the Infoblox WAPI endpoint (usually the grid master). This parameter is required if not already set using Set-IBWAPIConfig.

    .PARAMETER APIVersion
        The version of the Infoblox WAPI to make calls against (e.g. '2.2'). You may optionally specify 'latest' and the function will attempt to query the WAPI for the latest supported version. This will only work if ComputerName and Credential or WebSession are already configured.

    .PARAMETER Credential
        Username and password for the Infoblox appliance. This parameter is required unless -WebSession is specified or was already set using Set-IBWAPIConfig.

    .PARAMETER WebSession
        A WebRequestSession object returned by Get-IBSession or set when using Invoke-IBWAPI with the -SessionVariable parameter. This parameter is required unless -Credential is specified or was already set using Set-IBWAPIConfig.

    .PARAMETER IgnoreCertificateValidation
        If $true, SSL/TLS certificate validation will be disabled.

    .OUTPUTS
        The object reference string of the deleted item.

    .EXAMPLE
        $myhost = Get-IBObject -ObjectName 'record:host' -SearchFilters 'name=myhost'
        PS C:\>Remove-IBObject -ObjectRef $myhost._ref

        Search for a host record called 'myhost' and delete it.

    .LINK
        Project: https://github.com/rmbolger/Posh-IBWAPI

    .LINK
        New-IBObject

    .LINK
        Get-IBObject

    #>
}