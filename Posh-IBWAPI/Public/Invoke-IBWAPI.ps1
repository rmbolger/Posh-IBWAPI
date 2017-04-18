function Invoke-IBWAPI
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true,Position=0)]
        [Uri]$Uri,
        [Microsoft.PowerShell.Commands.WebRequestMethod]$Method=([Microsoft.PowerShell.Commands.WebRequestMethod]::Get),
        [PSCredential]$Credential,
        [Object]$Body,
        [string]$ContentType='application/json',
        [string]$SessionVariable,
        [Microsoft.PowerShell.Commands.WebRequestSession]$WebSession,
        [bool]$IgnoreCertificateValidation
    )

    ###########################################################################
    # This function is largely just a wrapper around Invoke-RestMethod that is able
    # to trap errors and present them to the caller in a more useful fashion.
    # For instance, HTTP 400 errors are normally returned as an Exception without
    # any context. But Infoblox returns details about *why* the request was bad in
    # the response body. So we swallow the original exception and throw a new one
    # with the specific error details.
    #
    # We also allow for disabling certificate validation on a per-call basis.
    # However, due to how the underlying .NET framework caches cert validation
    # results, hosts that were ignored may continue to be ignored for
    # a period of time after the initial call even if validation is turned
    # back on.
    ###########################################################################

    # Build a hashtable out of our optional parameters that we will later
    # send to Invoke-RestMethod via Splatting
    # https://msdn.microsoft.com/en-us/powershell/reference/5.1/microsoft.powershell.core/about/about_splatting
    $opts = @{}

    if ($Method) {
        $opts.Method = $Method
    }
    if ($Credential) {
        $opts.Credential = $Credential
    }
    if ($Body) {
        $opts.Body = $Body
    }
    if ($ContentType) {
        $opts.ContentType = $ContentType
    }
    if ($SessionVariable) {
        # change the name internally so we don't have trouble
        # with colliding variable names
        $opts.SessionVariable = 'innerSession'
    }
    if ($WebSession) {
        $opts.WebSession = $WebSession
    }

    try
    {
        if ($IgnoreCertificateValidation) { [CertValidation]::Ignore() }

        try {
            Invoke-RestMethod -Uri $Uri @opts

            # make sure to send our session variable up to the caller scope if defined
            if ($SessionVariable) {
                Set-Variable -Name $SessionVariable -Value $innerSession -Scope 2
            }
        }
        finally {
            if ($IgnoreCertificateValidation) { [CertValidation]::Restore() }
        }
    }
    catch
    {
        $response = $_.Exception.Response

        if ($response.StatusCode -eq [System.Net.HttpStatusCode]::BadRequest) {

            # get the response body so we can pull out the WAPI's error message
            $stream = $response.GetResponseStream()
            $reader = New-Object System.IO.StreamReader($stream)
            $reader.BaseStream.Position = 0
            $reader.DiscardBufferedData()
            $responseBody = $reader.ReadToEnd();

            Write-Verbose $responseBody
            $wapiErr = ConvertFrom-Json $responseBody
            throw [Exception] "$($wapiErr.Error)"

        } else {
            # just re-throw everything else
            throw
        }
    }




    <#
    .SYNOPSIS
        Send a request to the Infoblox WAPI (REST API).

    .DESCRIPTION
        This function is largely just a wrapper around Invoke-RestMethod that supports trapping and exposing syntax errors with the WAPI and the ability to ignore certificate validation. It is what all of the *-IBObject functions use under the hood and shouldn't be necessary to call directly most of the time.

    .PARAMETER Uri
        The full Uri of the WAPI endpoint. (e.g. https://gridmaster.example.com/wapi/v2.2/network)

    .PARAMETER Method
        The HTTP method to use in the request. Default is GET.

    .PARAMETER Credential
        Username and password for the Infoblox appliance. This parameter is required unless -WebSession is specified.

    .PARAMETER Body
        The body of the request. This is usually a JSON string if needed.

    .PARAMETER ContentType
        The Content-Type header for the request. Default is 'application/json'.

    .PARAMETER SessionVariable
        Specifies a variable for which this cmdlet creates a web request session and saves it in the value. Enter a variable name without the dollar sign ($) symbol.

    .PARAMETER IgnoreCertificateValidation
        If $true, SSL/TLS certificate validation will be disabled.

    .EXAMPLE
        Invoke-IBWAPI -Uri 'https://gridmaster.example.com/wapi/v2.2/network' -Credential (Get-Credential)

        Retrieve the list of network objects from the grid master using interactive credentials.

    .LINK
        Project: https://github.com/rmbolger/Posh-IBWAPI

    .LINK
        New-IBObject

    .LINK
        Get-IBObject

    .LINK
        Invoke-RestMethod

    #>
}
