function Receive-IBFile {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$True)]
        [Alias('name')]
        [string]$FunctionName,
        [Parameter(Mandatory=$True)]
        [string]$OutFile,
        [Alias('args')]
        [hashtable]$FunctionArgs,
        [Alias('host')]
        [string]$WAPIHost,
        [Alias('version')]
        [string]$WAPIVersion,
        [PSCredential]$Credential,
        [switch]$SkipCertificateCheck
    )

    Begin {
        # grab the variables we'll be using for our REST calls
        $opts = Initialize-CallVars @PSBoundParameters
    }

    Process {

        # requestion the download token and url
        $response = Invoke-IBFunction -ObjectRef 'fileop' `
            -FunctionName $FunctionName -FunctionArgs $FunctionArgs @opts -EA Stop
        $dlUrl = $response.url

        # try to download the file
        try {
            $dlOpts = @{
                Credential = $opts.Credential
                SkipCertificateCheck = $true
                ContentType = 'application/force-download'
            }
            Invoke-IBWAPI -Uri $dlUrl -OutFile $OutFile @dlOpts -EA Stop
        }
        finally {
            # inform Infoblox that the download is complete
            if ($response.token) {
                $null = Invoke-IBFunction -ObjectRef 'fileop' `
                    -FunctionName 'downloadcomplete' -FunctionArgs @{token=$response.token} @opts
            }
        }

    }




    <#
    .SYNOPSIS
        Download a file from a fileop function

    .DESCRIPTION
        This is a wrapper around the various fileop functions that allow data export from Infoblox.

    .PARAMETER FunctionName
        The name of the fileop download function to call.

    .PARAMETER OutFile
        Specifies the output file that this cmdlet saves the response body. Enter a path and file name. If you omit the path, the default is the current location.

    .PARAMETER FunctionArgs
        A hashtable with the required parameters for the function.  NOTE: 'token' parameters are handled automatically and can be ignored.

    .PARAMETER WAPIHost
        The fully qualified DNS name or IP address of the Infoblox WAPI endpoint (usually the grid master). This parameter is required if not already set using Set-IBConfig.

    .PARAMETER WAPIVersion
        The version of the Infoblox WAPI to make calls against (e.g. '2.2').

    .PARAMETER Credential
        Username and password for the Infoblox appliance. This parameter is required unless it was already set using Set-IBConfig.

    .PARAMETER SkipCertificateCheck
        If set, SSL/TLS certificate validation will be disabled. Overrides value stored with Set-IBConfig.

    .EXAMPLE
        Receive-IBFile getgriddata .\backup.tar.gz -args @{type='BACKUP'}

        Download a grid backup file using the 'getgriddata' fileop function.

    .EXAMPLE
        Receive-IBFile csv_export .\host-records.csv -args @{_object='record:host'}

        Download a CSV export of all host records using the 'csv_export' fileop function.

    .LINK
        Project: https://github.com/rmbolger/Posh-IBWAPI

    .LINK
        Invoke-IBFunction

    #>
}
