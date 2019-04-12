function HighestVer
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [string]$WAPIHost,
        [Parameter(Mandatory=$true)]
        [pscredential]$Credential,
        [switch]$SkipCertificateCheck,
        [Parameter(ValueFromRemainingArguments=$true)]
        $ExtraParams
    )

    try {
        # Query the grid master schema for the list of supported versions
        Write-Verbose "Querying schema for supported versions"
        $APIBase = $script:APIBaseTemplate -f $WAPIHost,'1.1'
        $versions = (Invoke-IBWAPI -Uri "$($APIBase)?_schema" -Credential $Credential -IgnoreCertificateValidation:$SkipCertificateCheck).supported_versions

        # Historically, these are returned in order. But just in case they aren't, we'll
        # explicitly sort them via the [Version] cast which is an easy way to make sure you
        # end up with 1,2,11,22 instead of 1,11,2,22.
        $versions = $versions | Sort-Object @{E={[Version]$_}}

        # set the most recent (last) one in the sorted list
        return $versions[-1]
    }
    catch {

        if ($_.ToString() -eq 'AdmConProtoError: Unknown argument: _schema=') {

            Write-Verbose "Schema query failed, attempting to scrape wapidoc HTML."

            # We're likely dealing with a pre-1.7.5 WAPI version that doesn't support
            # schema querying. So we're going to have to scrape the WAPI version
            # from /wapidoc HTML.
            $reVersion = '<title>.*WAPI ([\.0-9]+).*</title>'

            # get the wapidoc home page
            $docBase = $script:WAPIDocTemplate -f $WAPIHost
            $response = Invoke-RestMethod $docBase

            if ($response -match $reVersion) {
                # return the version we found
                return $matches[1]
            }
            else {
                throw "Unable to parse WAPI version from wapidoc HTML."
            }
        }
        else {
            # just re-throw everything else
            throw
        }
    }
}
