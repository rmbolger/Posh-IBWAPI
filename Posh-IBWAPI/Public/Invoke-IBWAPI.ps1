function Invoke-IBWAPI
{
    [CmdletBinding(SupportsShouldProcess,DefaultParameterSetName='Uri')]
    param(
        [Parameter(ParameterSetName='Uri',Mandatory=$true,Position=0)]
        [Uri]$Uri,
        [Parameter(ParameterSetName='HostVersion',Mandatory=$true,Position=0)]
        [Alias('host')]
        [string]$WAPIHost,
        [Parameter(ParameterSetName='HostVersion',Mandatory=$true,Position=1)]
        [Alias('version')]
        [string]$WAPIVersion,
        [Parameter(ParameterSetName='HostVersion',Mandatory=$true,Position=2)]
        [string]$Query,
        [Microsoft.PowerShell.Commands.WebRequestMethod]$Method=([Microsoft.PowerShell.Commands.WebRequestMethod]::Get),
        [PSCredential]$Credential,
        [Object]$Body,
        [string]$ContentType = 'application/json; charset=utf-8',
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

    # Built the URI if they passed individual Host+Version
    if ('HostVersion' -eq $PSCmdlet.ParameterSetName) {
        $apiBase = $script:APIBaseTemplate -f $WAPIHost,$WAPIVersion
        $Uri = '{0}{1}' -f $apiBase,$Query
    }

    # Build a hashtable of parameters that we will later send to Invoke-RestMethod via splatting
    $opts = @{
        Uri         = $Uri          # mandatory param
        Method      = $Method       # has default value, should always exist
        ContentType = $ContentType  # has default value, should always exist
        Verbose     = $false
        ErrorAction = 'Stop'
    }
    if ($PSBoundParameters.Credential) { $opts.Credential = $PSBoundParameters.Credential }
    if ($PSBoundParameters.OutFile)    { $opts.OutFile    = $PSBoundParameters.OutFile }
    if ($PSBoundParameters.WebSession) { $opts.WebSession = $PSBoundParameters.WebSession }

    if ($Body) {
        # If the ContentType was explicitly specified, we're going to assume the caller
        # wants the body passed to Invoke-RestMethod as-is. Otherwise, we're going to try
        # and make sure we send properly UTF-8 encoded JSON so non-ASCII characters don't
        # get messed up.
        if ($PSBoundParameters.ContentType) {
            Write-Debug "Using Body as-is"
            $opts.Body = $Body
            $bodyDebug = $Body
        }
        elseif ($Body -is [string]) {
            # A string value may or may not be valid JSON, but we're goint to UTF-8 encode
            # encode it anyway because the ContentType still claims it is.
            Write-Debug "UTF-8 encoding string Body"
            $opts.Body = [Text.Encoding]::UTF8.GetBytes($Body)
            $bodyDebug = $Body
        }
        else {
            # All that's left is some sort of object that should be JSON convertable
            Write-Debug "Converting Body to JSON and UTF-8 encoding"
            $opts.Body = [Text.Encoding]::UTF8.GetBytes(
                ($Body | ConvertTo-Json -Compress -Depth 5)
            )
            $bodyDebug = $Body | ConvertTo-Json -Depth 5
        }
    }

    # add Core edition parameters if necessary
    if ($SkipCertificateCheck -and $script:SkipCertSupported) {
        $opts.SkipCertificateCheck = $true
    }

    if ('SkipHeaderValidation' -in (Get-Command Invoke-RestMethod).Parameters.Keys) {
        # PS Core doesn't like the way our multipart Content-Type header looks for some
        # reason. So we need to disable its built-in validation.
        $opts.SkipHeaderValidation = $true
    }

    # deal with session stuff
    if ($opts.WebSession) {
        Write-Debug "using explicit session"
    } elseif ($savedSession = Get-IBSession $opts.Uri $opts.Credential) {
        $opts.WebSession = $savedSession
    } else {
        Write-Debug "creating new session"
        # prepare to save the session for later
        $opts.SessionVariable = 'innerSession'
    }

    try
    {
        if ($SkipCertificateCheck -and !$script:SkipCertSupported) {
            [CertValidation]::Ignore();
            Write-Verbose "Disabled cert validation"
        }

        try {
            $methodUpper = $opts.Method.ToString().ToUpper()

            if ($PSCmdlet.ShouldProcess($opts.Uri, $methodUpper)) {

                # send the request
                Write-Verbose "$methodUpper $($opts.Uri)"
                if ($bodyDebug) { Write-Verbose "Body:`n$bodyDebug" }
                $response = Invoke-RestMethod @opts

                # attempt to detect a master candidate's meta refresh tag
                if ($response -is [Xml.XmlDocument] -and $response.OuterXml -match 'CONTENT="0; URL=https://(?<gm>[\w.]+)"') {
                    $gridmaster = $matches.gm
                    Write-Warning "WAPIHost $($opts.Uri.Authority) is requesting a redirect to $gridmaster. Retrying request against that host."

                    # retry the request using the parsed grid master
                    $opts.Uri = [uri]$opts.Uri.ToString().Replace($opts.Uri.Authority, $gridmaster)
                    Write-Verbose "$methodUpper $($opts.Uri)"
                    if ($bodyDebug) { Write-Verbose "Body:`n$bodyDebug" }
                    Invoke-RestMethod @opts
                } else {
                    Write-Output $response
                }

                # make sure to send our session variable up to the caller scope if defined
                if ($savedSession) {
                    if ($SessionVariable) {
                        Set-Variable -Name $SessionVariable -Value $savedSession -Scope 2
                    }
                } else {
                    if ((-not $opts.WebSession) -and $SessionVariable) {
                        Set-Variable -Name $SessionVariable -Value $innerSession -Scope 2
                    }

                    # save the session variable internally to re-use later
                    Set-IBSession $opts.Uri $opts.Credential $innerSession
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
        $ex = $_.Exception
        $response = $ex.Response

        if ($response.StatusCode -in 400,404) {

            # Since we can't catch explicit exception types between PowerShell editions
            # without errors for non-existent types, we need to string match the type names
            # and re-throw anything we don't care about.
            $exType = $ex.GetType().FullName
            if ('System.Net.WebException' -eq $exType) {

                # This is the exception that gets thrown in PowerShell Desktop edition

                # grab the raw response body
                $sr = New-Object IO.StreamReader($response.GetResponseStream())
                $sr.BaseStream.Position = 0
                $sr.DiscardBufferedData()
                $body = $sr.ReadToEnd()
                Write-Debug "Error Body:`n$body"

            } elseif ('Microsoft.PowerShell.Commands.HttpResponseException' -eq $exType) {

                # This is the exception that gets thrown in PowerShell Core edition

                # Response object type depends on platform
                # Linux type: System.Net.Http.CurlHandler+CurlResponseMessage
                #   Mac type: ???
                #   Win type: System.Net.Http.HttpResponseMessage

                # Currently in PowerShell 6, there's no way to get the raw response body from an
                # HttpResponseException because they dispose the response stream.
                # https://github.com/PowerShell/PowerShell/issues/5555
                # https://get-powershellblog.blogspot.com/2017/11/powershell-core-web-cmdlets-in-depth.html
                # However, a "processed" version of the body is available via ErrorDetails.Message
                # which *should* work for us. The processing they're doing should only be removing HTML
                # tags. And since our body should be JSON, there shouldn't be any tags to remove.
                # So we'll just go with it for now until someone reports a problem.
                $body = $_.ErrorDetails.Message
                Write-Debug "Error Body:`n$body"

            } else {
                $PSCmdlet.WriteError([Management.Automation.ErrorRecord]::new(
                    $_, $null, [Management.Automation.ErrorCategory]::InvalidOperation, $null
                ))
                return
            }

            $wapiErr = ConvertFrom-Json $body -EA Ignore
            if ($wapiErr) {
                $PSCmdlet.WriteError([Management.Automation.ErrorRecord]::new(
                    $wapiErr.Error, $null, [Management.Automation.ErrorCategory]::InvalidOperation, $null
                ))
            } else {
                $PSCmdlet.WriteError([Management.Automation.ErrorRecord]::new(
                    $body, $null, [Management.Automation.ErrorCategory]::InvalidOperation, $null
                ))
            }

        } else {
            Write-Debug ($response | ConvertTo-Json)
            $PSCmdlet.WriteError($_)
        }
    }
}
