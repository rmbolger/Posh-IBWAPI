function Invoke-IBWAPI
{

    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true,Position=0)]
        [Uri]$Uri,
        [Microsoft.PowerShell.Commands.WebRequestMethod]$Method=([Microsoft.PowerShell.Commands.WebRequestMethod]::Get),
        [PSCredential]$Credential,
        [Object]$Body,
        [string]$ContentType
    )

    # This function is the crux of this module. Its job is to be a glorified wrapper around
    # Invoke-RestMethod that is able to trap errors and present them to the caller in a more
    # useful fashion. For instance, HTTP 400 errors are normally returned without any context
    # by Invoke-RestMethod. But Infoblox returns details about *why* the request was bad in
    # the response body. So we swallow the original exception and throw a new exception with
    # the specific error details.

    try
    {
        Invoke-RestMethod -Uri $Uri -Method $Method -Credential $Credential -Body $Body -ContentType $ContentType
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
            write-verbose $responseBody
            $wapiErr = ConvertFrom-Json $responseBody
            throw [Exception] "$($wapiErr.Error)"
        } else {
            throw
        }
    }

}
