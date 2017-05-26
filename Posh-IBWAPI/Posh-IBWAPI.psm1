#Requires -Version 3.0

# Add our custom type for manipulating .NET cert validation
if (-not ([System.Management.Automation.PSTypeName]'CertValidation').Type)
{
    Add-Type @"
        using System.Net;
        using System.Net.Security;
        using System.Security.Cryptography.X509Certificates;
        public class CertValidation
        {
            static bool IgnoreValidation(object o, X509Certificate c, X509Chain ch, SslPolicyErrors e) {
                return true;
            }
            public static void Ignore() {
                ServicePointManager.ServerCertificateValidationCallback = IgnoreValidation;
            }
            public static void Restore() {
                ServicePointManager.ServerCertificateValidationCallback = null;
            }
        }
"@
}

# In all of the PowerShell environments tested so far, the set of supported TLS protocols
# configured by default in .NET seem to only include SSLv3 and TLSv1.0. So even if .NET
# supports using things like TLS 1.1 or 1.2, cmdlets like Invoke-RestMethod will be limited
# to TLS 1.0 unless the setting is overridden (per session).
#
# NIOS's default config supports TLS 1.0+, but since 8.x it's now possible to explicitly set
# supported TLS types. So if an environment disables TLS 1.0 support, Invoke-RestMethod fails
# with the following error:
# "The underlying connection was closed: An unexpected error occurred on a send."
#
# To give users a more secure default when using this module and try to prevent potential errors
# when running against grids who have customized their supported protocols, we will change
# the default set of protocols to include all protocol types beyond 1.0 (or currently configured
# max level) supported in the current installed .NET framework.
$currentMaxTls = [Math]::Max([Net.ServicePointManager]::SecurityProtocol.value__,[Net.SecurityProtocolType]::Tls.value__)
$newTlsTypes = [enum]::GetValues('Net.SecurityProtocolType') | ?{ $_ -gt $currentMaxTls }
$newTlsTypes | %{
    [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor $_
}

# initialize the config container related stuff
$script:CurrentHost = [string]::Empty
if (!$script:Config) { $script:Config = @{} }
if (!$script:Config.$script:CurrentHost) { $script:Config.$script:CurrentHost = @{WAPIHost=$script:CurrentHost} }

# Get public and private function definition files.
$Public  = @( Get-ChildItem -Path $PSScriptRoot\Public\*.ps1 -ErrorAction SilentlyContinue )
$Private = @( Get-ChildItem -Path $PSScriptRoot\Private\*.ps1 -ErrorAction SilentlyContinue )

# Dot source the files
Foreach($import in @($Public + $Private))
{
    Try
    {
        . $import.fullname
    }
    Catch
    {
        Write-Error -Message "Failed to import function $($import.fullname): $_"
    }
}

# Export everything in the public folder
Export-ModuleMember -Function $Public.Basename
