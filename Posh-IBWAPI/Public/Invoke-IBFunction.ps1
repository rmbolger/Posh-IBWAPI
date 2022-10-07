function Invoke-IBFunction
{
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory=$True,ValueFromPipeline=$True,ValueFromPipelineByPropertyName=$True)]
        [Alias('_ref','ref')]
        [string]$ObjectRef,
        [Parameter(Mandatory=$True)]
        [Alias('name')]
        [string]$FunctionName,
        [Alias('args')]
        [PSObject]$FunctionArgs,
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

        $queryParams = @{
            Query = '{0}?_function={1}' -f $ObjectRef,$FunctionName
            Method = 'POST'
        }
        if ($FunctionArgs) {
            $queryParams.Body = $FunctionArgs
        }

        # make the call
        if ($PSCmdlet.ShouldProcess($queryParams.Uri, "POST")) {
            Invoke-IBWAPI @queryParams @opts
        }

    }
}
