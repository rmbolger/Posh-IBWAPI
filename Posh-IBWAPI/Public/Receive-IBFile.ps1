function Receive-IBFile {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$True)]
        [Alias('name')]
        [string]$FunctionName,
        [Parameter(Mandatory=$True)]
        [string]$OutFile,
        [Alias('args')]
        [PSObject]$FunctionArgs,
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
            $uploadOpts = @{
                Credential = $opts.Credential
                IgnoreCertificateValidation = $true
            }
            Invoke-IBWAPI -Uri $response.url -OutFile $OutFile -ContentType 'application/force-download' @uploadOpts -EA Stop
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
        An object with the required parameters for the function.

    .PARAMETER WAPIHost
        The fully qualified DNS name or IP address of the Infoblox WAPI endpoint (usually the grid master). This parameter is required if not already set using Set-IBWAPIConfig.

    .PARAMETER WAPIVersion
        The version of the Infoblox WAPI to make calls against (e.g. '2.2').

    .PARAMETER Credential
        Username and password for the Infoblox appliance. This parameter is required unless -WebSession is specified or was already set using Set-IBWAPIConfig.

    .PARAMETER WebSession
        A WebRequestSession object returned by Get-IBSession or set when using Invoke-IBWAPI with the -SessionVariable parameter. This parameter is required unless -Credential is specified or was already set using Set-IBWAPIConfig.

    .PARAMETER IgnoreCertificateValidation
        If set, SSL/TLS certificate validation will be disabled. Overrides value stored with Set-IBWAPIConfig.

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
