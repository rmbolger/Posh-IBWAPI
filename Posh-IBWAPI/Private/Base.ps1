function Base
{
    [CmdletBinding()]
    param (
        [string]$WAPIHost,
        [string]$WAPIVersion,
        [Parameter(ValueFromRemainingArguments = $true)]
        $Splat
    )

    "https://$WAPIHost/wapi/v$WAPIVersion/"
}