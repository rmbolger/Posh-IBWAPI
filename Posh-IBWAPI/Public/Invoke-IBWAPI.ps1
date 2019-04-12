function Invoke-IBWAPI
{
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory=$true,Position=0)]
        [Uri]$Uri,
        [Microsoft.PowerShell.Commands.WebRequestMethod]$Method=([Microsoft.PowerShell.Commands.WebRequestMethod]::Get),
        [PSCredential]$Credential,
        [Object]$Body,
        [string]$ContentType='application/json; charset=utf-8',
        [string]$OutFile,
        [string]$SessionVariable,
        [Microsoft.PowerShell.Commands.WebRequestSession]$WebSession,
        [switch]$SkipCertificateCheck
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
    # back on. This issue only affects the Desktop edition.
    ###########################################################################

    # Build a hashtable out of our optional parameters that we will later
    # send to Invoke-RestMethod via splatting
    # https://msdn.microsoft.com/en-us/powershell/reference/5.1/microsoft.powershell.core/about/about_splatting
    $opts = @{}
    $paramNames = 'Method','Credential','Body','ContentType','OutFile','WebSession'
    $PSBoundParameters.Keys | Where-Object { $_ -in $paramNames } | ForEach-Object { $opts.$_ = $PSBoundParameters.$_ }

    # parameters with default values don't appear in $PSBoundParameters, so we need to add manually
    if (-not $opts.Method) { $opts.Method = $Method }
    if (-not $opts.ContentType) { $opts.ContentType = $ContentType }

    # add Core edition parameters if necessary
    if ($SkipCertificateCheck -and $script:SkipCertSupported) {
        $opts.SkipCertificateCheck = $true
    }

    if ($SessionVariable) {
        # change the name internally so we don't have trouble
        # with colliding variable names
        $opts.SessionVariable = 'innerSession'
    }

    if ('SkipHeaderValidation' -in (Get-Command Invoke-RestMethod).Parameters.Keys) {
        # PS Core doesn't like the way our multipart Content-Type header looks for some
        # reason. So we need to disable its built-in validation.
        $opts.SkipHeaderValidation = $true
    }

    try
    {
        if ($SkipCertificateCheck -and !$script:SkipCertSupported) {
            [CertValidation]::Ignore();
            Write-Verbose "Disabled cert validation"
        }

        try {
            if ($PSCmdlet.ShouldProcess($Uri, $opts.Method)) {

                # send the request
                $response = Invoke-RestMethod -Uri $Uri @opts

                # attempt to detect a master candidate's meta refresh tag
                if ($response -is [Xml.XmlDocument] -and $response.OuterXml -match 'CONTENT="0; URL=https://(?<gm>[\w.]+)"') {
                    $gridmaster = $matches.gm
                    Write-Warning "WAPIHost $($Uri.Authority) is requesting a redirect to $gridmaster. Retrying request against that host."

                    # retry the request using the parsed grid master
                    $Uri = [uri]$Uri.ToString().Replace($Uri.Authority, $gridmaster)
                    Invoke-RestMethod -Uri $Uri @opts
                } else {
                    $response
                }

                # make sure to send our session variable up to the caller scope if defined
                if ($SessionVariable) {
                    Set-Variable -Name $SessionVariable -Value $innerSession -Scope 2
                }
            }
        }
        finally {
            if ($SkipCertificateCheck -and !$script:SkipCertSupported) {
                [CertValidation]::Restore();
                Write-Verbose "Enabled cert validation"
            }
        }
    }
    catch
    {
        $response = $_.Exception.Response

        if ($response.StatusCode -eq [System.Net.HttpStatusCode]::BadRequest) {

            # Since we can't catch explicit exception types between PowerShell editions
            # without errors for non-existent types, we need to string match the type names
            # and re-throw anything we don't care about.
            $exType = $_.Exception.GetType().FullName
            if ('System.Net.WebException' -eq $exType) {

                # This is the exception that gets thrown in PowerShell Desktop edition

                # get the response object: System.Net.HttpWebResponse
                $response = $_.Exception.Response

                # grab the raw response body
                $sr = New-Object IO.StreamReader($response.GetResponseStream())
                $sr.BaseStream.Position = 0
                $sr.DiscardBufferedData()
                $body = $sr.ReadToEnd()
                Write-Debug "Error Body: $body"

            } elseif ('Microsoft.PowerShell.Commands.HttpResponseException' -eq $exType) {

                # This is the exception that gets thrown in PowerShell Core edition

                # get the response object
                # Linux type: System.Net.Http.CurlHandler+CurlResponseMessage
                #   Mac type: ???
                #   Win type: System.Net.Http.HttpResponseMessage
                $response = $_.Exception.Response

                # Currently in PowerShell 6, there's no way to get the raw response body from an
                # HttpResponseException because they dispose the response stream.
                # https://github.com/PowerShell/PowerShell/issues/5555
                # https://get-powershellblog.blogspot.com/2017/11/powershell-core-web-cmdlets-in-depth.html
                # However, a "processed" version of the body is available via ErrorDetails.Message
                # which *should* work for us. The processing they're doing should only be removing HTML
                # tags. And since our body should be JSON, there shouldn't be any tags to remove.
                # So we'll just go with it for now until someone reports a problem.
                $body = $_.ErrorDetails.Message
                Write-Debug "Error Body: $body"

            } else { throw }

            Write-Verbose $body
            $wapiErr = ConvertFrom-Json $body -EA SilentlyContinue
            if ($wapiErr) {
                throw [Exception] "$($wapiErr.Error)"
            } else {
                throw [Exception] $body
            }

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
        The body of the request. This is usually a JSON string if needed. NOTE: If you have non-ASCII characters, you may need to explicitly encode your JSON body as UTF-8. For example, [Text.Encoding]::UTF8.GetBytes($body).

    .PARAMETER ContentType
        The Content-Type header for the request. Default is 'application/json; charset=utf-8'.

    .PARAMETER OutFile
        Specifies the output file that this cmdlet saves the response body. Enter a path and file name. If you omit the path, the default is the current location.

    .PARAMETER SessionVariable
        Specifies a variable for which this cmdlet creates a web request session and saves it in the value. Enter a variable name without the dollar sign ($) symbol.

    .PARAMETER SkipCertificateCheck
        If set, SSL/TLS certificate validation will be disabled.

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
