function Send-IBFile {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true,Position=0)]
        [Alias('name')]
        [string]$FunctionName,
        [Parameter(Mandatory=$true,Position=1,
            ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true)]
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
        [Alias('args')]
        [hashtable]$FunctionArgs = @{},
        [Alias('_ref','ref','ObjectType','type')]
        [string]$ObjectRef = 'fileop',
        [switch]$OverrideTransferHost,

        [ValidateScript({Test-NonEmptyString $_ -ThrowOnFail})]
        [Alias('host')]
        [string]$WAPIHost,
        [ValidateScript({Test-VersionString $_ -ThrowOnFail})]
        [Alias('version')]
        [string]$WAPIVersion,
        [PSCredential]$Credential,
        [switch]$SkipCertificateCheck,
        [ValidateScript({Test-ValidProfile $_ -ThrowOnFail})]
        [string]$ProfileName
    )

    Begin {
        # grab the variables we'll be using for our REST calls
        try { $opts = Initialize-CallVars @PSBoundParameters } catch { $PsCmdlet.ThrowTerminatingError($_) }
    }

    Process {
        # Resolve relative paths
        $Path = $psCmdlet.SessionState.Path.GetUnresolvedProviderPathFromPSPath($Path)

        Write-Debug "Calling uploadinit"
        $response = Invoke-IBFunction -ObjectRef 'fileop' -FunctionName 'uploadinit' @opts -EA Stop
        $token = $response.token
        $uploadUrl = $response.url

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
                    Write-Verbose "Overrode URL host: $($opts.WAPIHost)"
                } else {
                    Write-Verbose "URL host already matches original. No need to override."
                }

                # and now match the state of SkipCertificateCheck
                $restOpts.SkipCertificateCheck = $opts.SkipCertificateCheck.IsPresent
            }

            # upload the file to the designated URL
            Write-Debug "Uploading file"
            Invoke-IBWAPI @restOpts
        } catch {
            throw
        } finally {
            if ($null -ne $multipart) { $multipart.Dispose() }
        }

        # add/update the token in the function args
        $FunctionArgs["token"] = $token

        # finalize the upload with the actual requested function and arguments
        Write-Debug "Calling $FunctionName with associated arguments"
        $response = Invoke-IBFunction -ObjectRef $ObjectRef -FunctionName $FunctionName `
            -FunctionArgs $FunctionArgs @opts -EA Stop

    }



    <#
    .SYNOPSIS
        Upload a file to Infoblox using one of the fileop upload functions.

    .DESCRIPTION
        This is a wrapper around the various fileop functions that allow data import into Infoblox.

    .PARAMETER FunctionName
        The name of the fileop upload function to call.

    .PARAMETER Path
        The path to the file that will be uploaded for this call.

    .PARAMETER FunctionArgs
        A hashtable with the required parameters for the function. NOTE: 'token' parameters are handled automatically and can be ignored.

    .PARAMETER ObjectRef
        Object reference string. This is usually found in the "_ref" field of returned objects.

    .PARAMETER OverrideTransferHost
        If set, the hostname in the transfer URL returned by WAPI will be overridden to match the original WAPIHost if they don't already match. The SkipCertificateCheck switch will also be updated to match the passed in value instead of always being set to true for the call.

    .PARAMETER WAPIHost
        The fully qualified DNS name or IP address of the Infoblox WAPI endpoint (usually the grid master). This parameter is required if not already set using Set-IBConfig.

    .PARAMETER WAPIVersion
        The version of the Infoblox WAPI to make calls against (e.g. '2.2'). This parameter is required if not already set using Set-IBConfig.

    .PARAMETER Credential
        Username and password for the Infoblox appliance. This parameter is required unless it was already set using Set-IBConfig.

    .PARAMETER SkipCertificateCheck
        If set, SSL/TLS certificate validation will be disabled. Overrides value stored with Set-IBConfig.

    .EXAMPLE
        Send-IBFile uploadcertificate .\ca.pem -FunctionArgs @{certificate_usage='EAP_CA'}

        Upload a trusted CA certificate to the grid.

    .LINK
        Project: https://github.com/rmbolger/Posh-IBWAPI

    .LINK
        Receive-IBFile

    #>
}
