function Get-ReadFieldsForType {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory,Position=0)]
        [string]$ObjectType,
        [string]$WAPIHost,
        [string]$WAPIVersion,
        [PSCredential]$Credential,
        [switch]$SkipCertificateCheck,
        [switch]$NoSession
    )

    $opts = [hashtable]::new($PSBoundParameters)
    $null = $opts.Remove('ObjectType')

    # grab the read fields cache for this host
    $rfCache = $script:Schemas.$WAPIHost.ReadFields

    # Return existing answer if we have one for this version/type combo
    $fieldKey = '{0}|{1}' -f $WAPIVersion,$ObjectType
    if ($readFields = $rfCache.$fieldKey) {
        Write-Debug "Using existing read fields cache for $fieldKey"
        return $readFields
    }

    Write-Verbose "Querying schema for $ObjectType fields on version $WAPIVersion"
    $schema = Get-IBSchema $ObjectType -Raw @opts

    # add the readable fields to the cache and return them
    $readFields = $schema.fields |
        Where-Object { $_.supports -like '*r*' -and $_.wapi_primitive -ne 'funccall' } |
        Select-Object -Expand name
    $rfCache.$fieldKey = $readFields
    return $readFields

}
