function Send-IBFile {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory,Position=0)]
        [Alias('name')]
        [string]$FunctionName,
        [Parameter(Mandatory,Position=1,ValueFromPipeline,ValueFromPipelineByPropertyName)]
        [Alias("PSPath")]
        [ValidateScript({
            if(-not ($_ | Test-Path) ) {
                throw "File or folder does not exist"
            }
            if(-not ($_ | Test-Path -PathType Leaf) ) {
                throw "The Path argument must be a file. Folder paths are not allowed."
            }
            return $true
        })]
        [string]$Path,
        [Parameter(Position=2)]
        [Alias('args')]
        [Collections.IDictionary]$FunctionArgs = @{},
        [Parameter(Position=3)]
        [Alias('_ref','ref','ObjectType','type')]
        [string]$ObjectRef = 'fileop',
        [switch]$OverrideTransferHost,

        [ValidateScript({Test-ValidProfile $_ -ThrowOnFail})]
        [string]$ProfileName,
        [ValidateScript({Test-NonEmptyString $_ -ThrowOnFail})]
        [Alias('host')]
        [string]$WAPIHost,
        [ValidateScript({Test-VersionString $_ -ThrowOnFail})]
        [Alias('version')]
        [string]$WAPIVersion,
        [PSCredential]$Credential,
        [switch]$SkipCertificateCheck,
        [switch]$NoSession
    )

    Begin {
        # grab the variables we'll be using for our REST calls
        try { $opts = Initialize-CallVars @PSBoundParameters } catch { $PsCmdlet.ThrowTerminatingError($_) }
    }

    Process {
        # Resolve relative paths
        $Path = $psCmdlet.SessionState.Path.GetUnresolvedProviderPathFromPSPath($Path)

        Write-Debug "Calling uploadinit"
        try {
            $response = Invoke-IBFunction -ObjectRef 'fileop' -FunctionName 'uploadinit' @opts -EA Stop
            $token = $response.token
            $uploadUrl = $response.url
        } catch { $PsCmdlet.ThrowTerminatingError($_) }

        # while we'd love to use the built-in support for multipart/file uploads in Invoke-RestMethod, it's
        # only available in PowerShell 6.1+ and the implementation currently has some bugs we'd need
        # to work around anyway. So we have to do things a bit more manually.

        $multipart = New-MultipartFileContent (Get-ChildItem $Path)
        $contentType = $multipart.Headers.ContentType.ToString()
        Write-Debug "ContentType: $contentType"
        $bodyBytes = $multipart.ReadAsByteArrayAsync().Result
        $body = [Text.Encoding]::GetEncoding('iso-8859-1').GetString($bodyBytes)

        try {
            $restOpts = @{
                Uri = $uploadUrl
                Method = 'Post'
                ContentType = $contentType
                Body = $body
                Credential = $opts.Credential
                SkipCertificateCheck = $true
                ErrorAction = 'Stop'
            }

            if ($OverrideTransferHost) {
                # make sure the host portion of the URL matches the original WAPIHost
                $urlHost = ([uri]$restOpts.Uri).Host
                if ($opts.WAPIHost -ne $urlHost) {
                    $restOpts.Uri = $restOpts.Uri.Replace("https://$urlHost/", "https://$($opts.WAPIHost)/")
                    Write-Debug "Overrode URL host: $($opts.WAPIHost)"
                } else {
                    Write-Debug "URL host already matches original. No need to override."
                }

                # and now match the state of SkipCertificateCheck
                $restOpts.SkipCertificateCheck = $opts.SkipCertificateCheck
            }

            # upload the file to the designated URL
            Write-Debug "Uploading file"
            Invoke-IBWAPI @restOpts
        } catch {
            $PsCmdlet.ThrowTerminatingError($_)
        } finally {
            if ($null -ne $multipart) { $multipart.Dispose() }
        }

        # add/update the token in the function args
        $FunctionArgs.token = $token

        # finalize the upload with the actual requested function and arguments
        Write-Debug "Calling $FunctionName with associated arguments"
        $funcParams = @{
            ObjectRef = $ObjectRef
            FunctionName = $FunctionName
            FunctionArgs = $FunctionArgs
            ErrorAction = 'Stop'
        }
        try {
            $response = Invoke-IBFunction @funcParams @opts
        } catch { $PsCmdlet.ThrowTerminatingError($_) }

    }
}
