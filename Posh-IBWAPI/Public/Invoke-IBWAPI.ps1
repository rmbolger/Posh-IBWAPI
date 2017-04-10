function Invoke-IBWAPI
{

    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true,Position=0)]
        [Uri]$Uri,
        [Microsoft.PowerShell.Commands.WebRequestMethod]$Method=([Microsoft.PowerShell.Commands.WebRequestMethod]::Get),
        [PSCredential]$Credential,
        [Object]$Body,
        [string]$ContentType,
        [string]$SessionVariable,
        [Microsoft.PowerShell.Commands.WebRequestSession]$WebSession
    )

    # Build a hashtable out of our optional parameters that we will later
    # send to Invoke-RestMethod via Splatting
    # https://msdn.microsoft.com/en-us/powershell/reference/5.1/microsoft.powershell.core/about/about_splatting
    $opts = @{}

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

    # This function is the crux of this module. Its job is to be a wrapper around
    # Invoke-RestMethod that is able to trap errors and present them to the caller in a more
    # useful fashion. For instance, HTTP 400 errors are normally returned without any context
    # by Invoke-RestMethod. But Infoblox returns details about *why* the request was bad in
    # the response body. So we swallow the original exception and throw a new exception with
    # the specific error details.

    try
    {
        Invoke-RestMethod -Uri $Uri @opts

        # make sure to send our session variable up to the caller scope if defined
        if ($SessionVariable) {
            Write-Verbose "SessionVariable: $SessionVariable"
            Write-Verbose "`$innerSession: $innerSession"
            Set-Variable -Name $SessionVariable -Value $innerSession -Scope 2
            Write-Verbose "`$$($SessionVariable): $(Get-Variable -Name $SessionVariable -ValueOnly)"
        }
    }
    catch
    {
        $response = $_.Exception.Response

        if ($response.StatusCode -eq [System.Net.HttpStatusCode]::BadRequest) {

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

}
