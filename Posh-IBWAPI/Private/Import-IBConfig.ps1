function Import-IBConfig
{
    [CmdletBinding()]
    param()

    # initialize empty profiles
    Set-CurrentProfile ([string]::Empty)
    $profiles = $script:Profiles = @{}

    # make sure session and schema caches are initialized
    if (-not $script:Sessions) {
        $script:Sessions = @{}
    }
    if (-not $script:Schemas) {
        $script:Schemas = @{}
    }

    # Check for an environment variable based profile overriding anything else
    if (Test-NonEmptyString $env:IBWAPI_HOST) {

        if ($env:IBWAPI_VERSION -and (Test-VersionString $env:IBWAPI_VERSION)) {

            if (Test-NonEmptyString $env:IBWAPI_USERNAME) {

                if (Test-NonEmptyString $env:IBWAPI_PASSWORD) {

                    # securify the password
                    $secPass = ConvertTo-SecureString $env:IBWAPI_PASSWORD -AsPlainText -Force

                    # add the profile
                    Set-CurrentProfile 'ENV'
                    $profiles.ENV = @{
                        WAPIHost    = $env:IBWAPI_HOST
                        WAPIVersion = $env:IBWAPI_VERSION
                        Credential  = [pscredential]::new($env:IBWAPI_USERNAME,$secPass)
                    }

                    # Check for optional skip cert check. Any value other than the explicit
                    # set of "no" strings will be treated as $true
                    $falseStrings = 'False','0','No'
                    if ($env:IBWAPI_SKIPCERTCHECK -and $env:IBWAPI_SKIPCERTCHECK -notin $falseStrings) {
                        $profiles.ENV.SkipCertificateCheck = $true
                    } else {
                        $profiles.ENV.SkipCertificateCheck = $false
                    }
                    Write-Verbose "Using env variable profile $($env:IBWAPI_USERNAME) @ $($env:IBWAPI_HOST) $($env:IBWAPI_VERSION)"

                    # don't bother trying to load the local profiles
                    return
                }
                else {
                    Write-Warning "IBWAPI_PASSWORD environment variable missing or empty. Unable to use environment variable profile."
                }
            }
            else {
                Write-Warning "IBWAPI_USERNAME environment variable missing or empty. Unable to use environment variable profile."
            }
        }
        else {
            Write-Warning "IBWAPI_VERSION environment variable missing or invalid. Unable to use environment variable profile."
        }
    }

    # return early if there's no file to load
    $configFile = Get-ConfigFile
    if (-not (Test-Path $configFile -PathType Leaf)) { return }

    # load the json content on disk to a pscustomobject
    try {
        $json = Get-Content $configFile -Encoding UTF8 -Raw | ConvertFrom-Json
    } catch {
        Write-Warning "Unable to parse existing config file: $($_.Exception.Message)"
        return
    }

    $propNames = @($json.PSObject.Properties.Name)

    # grab the current profile
    if ('CurrentProfile' -in $propNames) {
        Set-CurrentProfile $json.CurrentProfile
    }

    # load the rest of the profiles
    if ('Profiles' -in $propNames) {
        $json.Profiles.PSObject.Properties.Name | ForEach-Object {
            $profiles.$_ = @{
                WAPIHost    = $json.Profiles.$_.WAPIHost
                WAPIVersion = $json.Profiles.$_.WAPIVersion
                Credential  = $null
                SkipCertificateCheck = $false
            }
            if ('Credential' -in $json.Profiles.$_.PSObject.Properties.Name) {
                $profiles.$_.Credential = (Import-IBCred $json.Profiles.$_.Credential $_)
            }
            if ($json.Profiles.$_.SkipCertificateCheck) {
                $profiles.$_.SkipCertificateCheck = $true
            }
        }
    }

}
