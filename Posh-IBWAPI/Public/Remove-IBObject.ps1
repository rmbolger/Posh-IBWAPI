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

    Invoke-IBWAPI -Method Delete -Uri "$($cfg.APIBase)$($ObjectRef)" -WebSession $cfg.WebSession -ContentType 'application/json' -IgnoreCertificateValidation $cfg.IgnoreCertificateValidation




    <#
    .SYNOPSIS
        Delete an object from Infoblox.

    .DESCRIPTION
        Specify an object reference to delete that object from the Infoblox database.

    .PARAMETER ObjectRef
        Object reference string. This is usually found in the "_ref" field of returned objects.

    .PARAMETER ComputerName
        TODO

    .PARAMETER APIVersion
        TODO

    .PARAMETER Credential
        TODO

    .PARAMETER WebSession
        TODO

    .PARAMETER IgnoreCertificateValidation
        TODO

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