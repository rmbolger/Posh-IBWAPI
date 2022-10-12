function Receive-IBFile {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory,Position=0)]
        [Alias('name')]
        [string]$FunctionName,
        [Parameter(Mandatory,Position=1)]
        [string]$OutFile,
        [Parameter(Position=2)]
        [Alias('args')]
        [Collections.IDictionary]$FunctionArgs,
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
        [switch]$SkipCertificateCheck
    )

    Begin {
        # grab the variables we'll be using for our REST calls
        try { $opts = Initialize-CallVars @PSBoundParameters } catch { $PsCmdlet.ThrowTerminatingError($_) }
    }

    Process {

        # requestion the download token and url
        $response = Invoke-IBFunction -ObjectRef $ObjectRef `
            -FunctionName $FunctionName -FunctionArgs $FunctionArgs @opts -EA Stop
        $dlUrl = $response.url

        # try to download the file
        try {
            $restOpts = @{
                Uri = $dlUrl
                OutFile = $OutFile
                Credential = $opts.Credential
                SkipCertificateCheck = $true
                ContentType = 'application/force-download'
                ErrorAction = 'Stop'
            }

            # We need to add an empty Body parameter on PowerShell Core to work around
            # this bug which kills the ContentType we set.
            # https://github.com/PowerShell/PowerShell/issues/9574
            if ($PSEdition -and $PSEdition -eq 'Core') {
                $restOpts.Body = [String]::Empty
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

            # download the file from the designated URL
            Write-Debug "Downloading file"
            Invoke-IBWAPI @restOpts
        }
        finally {
            # inform Infoblox that the download is complete
            if ($response.token) {
                $null = Invoke-IBFunction -ObjectRef 'fileop' `
                    -FunctionName 'downloadcomplete' -FunctionArgs @{token=$response.token} @opts
            }
        }

    }
}
