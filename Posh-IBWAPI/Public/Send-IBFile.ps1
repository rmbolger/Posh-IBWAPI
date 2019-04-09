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
        [hashtable]$FunctionArgs,

        [Alias('host')]
        [string]$WAPIHost,
        [Alias('version')]
        [string]$WAPIVersion,
        [PSCredential]$Credential,
        [Alias('session')]
        [Microsoft.PowerShell.Commands.WebRequestSession]$WebSession,
        [switch]$IgnoreCertificateValidation
    )

    Begin {
        # grab the variables we'll be using for our REST calls
        $opts = Initialize-CallVars @PSBoundParameters
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
        $body = $multipart.ReadAsStringAsync().Result
        Write-Debug "Body:`n$body"

        try {
            $uploadOpts = @{
                Credential = $opts.Credential
                IgnoreCertificateValidation = $true
                ContentType = $contentType
            }

            # upload the file to the designated URL
            Write-Debug "Uploading file"
            Invoke-IBWAPI $uploadUrl -Method Post -Body $body @uploadOpts -EA Stop
        } catch {
            throw
        } finally {
            if ($null -ne $multipart) { $multipart.Dispose() }
        }

        # add/update the token in the function args
        $FunctionArgs.token = $token

        # finalize the upload with the actual requested function and arguments
        Write-Debug "Calling $FunctionName with associated arguments"
        $response = Invoke-IBFunction -ObjectRef 'fileop' -FunctionName $FunctionName `
            -FunctionArgs $FunctionArgs @opts -EA Stop

    }

}
