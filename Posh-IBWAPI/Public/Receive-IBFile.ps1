function Receive-IBFile {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$True)]
        [Alias('name')]
        [string]$FunctionName,
        [Alias('args')]
        [PSObject]$FunctionArgs,
        [string]$OutFile,
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

        # requestion the download token and url
        $response = Invoke-IBFunction -ObjectRef 'fileop' `
            -FunctionName $FunctionName -FunctionArgs $FunctionArgs @opts -EA Stop

        # try to download the file
        try {
            $creds = @{Credential=$opts.Credential; WebSession=$opts.WebSession}
            Invoke-IBWAPI -Uri $response.url -OutFile $OutFile -ContentType 'application/force-download' @creds -EA Stop
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
