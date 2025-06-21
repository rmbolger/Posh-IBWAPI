function Get-EnvProfile {
    [CmdletBinding()]
    param()

    # Return nothing unless the minimum profile components are defined.

    # check for non-empty host
    if ([string]::IsNullOrWhiteSpace($env:IBWAPI_HOST)) {
        return
    }

    # check for valid version string
    if (-not ($env:IBWAPI_VERSION -and (Test-VersionString $env:IBWAPI_VERSION))) {
        Write-Warning "IBWAPI_VERSION environment variable missing or invalid. Unable to use environment variable profile."
        return
    }

    # check for non-empty username
    if ([string]::IsNullOrWhiteSpace($env:IBWAPI_USERNAME)) {
        Write-Warning "IBWAPI_USERNAME environment variable missing or empty. Unable to use environment variable profile."
        return
    }

    # check for non-empty password
    if ([string]::IsNullOrWhiteSpace($env:IBWAPI_PASSWORD)) {
        Write-Warning "IBWAPI_PASSWORD environment variable missing or empty. Unable to use environment variable profile."
        return
    }

    # securify the password
    $secPass = ConvertTo-SecureString $env:IBWAPI_PASSWORD -AsPlainText -Force

    # create a hashtable with profile details to return
    $prof = @{
        WAPIHost    = $env:IBWAPI_HOST
        WAPIVersion = $env:IBWAPI_VERSION
        Credential  = [pscredential]::new($env:IBWAPI_USERNAME,$secPass)
    }

    # Check for optional skip cert check. Any value other than the explicit
    # set of "no" strings will be treated as $true
    $falseStrings = 'False','0','No'
    if ($env:IBWAPI_SKIPCERTCHECK -and $env:IBWAPI_SKIPCERTCHECK -notin $falseStrings) {
        $prof.SkipCertificateCheck = $true
    } else {
        $prof.SkipCertificateCheck = $false
    }

    # Check for optional skip cert check. Any value other than the explicit
    # set of "no" strings will be treated as $true
    $falseStrings = 'False','0','No'
    if ($env:IBWAPI_NOSESSION -and $env:IBWAPI_NOSESSION -notin $falseStrings) {
        $prof.NoSession = $true
    } else {
        $prof.NoSession = $false
    }

    return $prof
}
