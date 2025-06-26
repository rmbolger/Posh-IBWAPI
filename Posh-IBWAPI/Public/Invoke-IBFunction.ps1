function Invoke-IBFunction
{
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory,Position=0,ValueFromPipeline,ValueFromPipelineByPropertyName)]
        [Alias('_ref','ref')]
        [string]$ObjectRef,
        [Parameter(Mandatory,Position=1)]
        [Alias('name')]
        [string]$FunctionName,
        [Parameter(Position=2)]
        [Alias('args')]
        [PSObject]$FunctionArgs,

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

        $queryParams = @{
            Query = '{0}?_function={1}' -f $ObjectRef,$FunctionName
            Method = 'POST'
            ErrorAction = 'Stop'
        }
        if ($FunctionArgs) {
            $queryParams.Body = $FunctionArgs
        }

        # make the call
        if ($PSCmdlet.ShouldProcess($queryParams.Uri, "POST")) {
            try {
                Invoke-IBWAPI @queryParams @opts
            } catch { $PsCmdlet.WriteError($_) }

        }

    }
}
