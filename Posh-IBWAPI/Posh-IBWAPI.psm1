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

# initialize the config container related stuff
if (!$script:CurrentHost) { $script:CurrentHost = [string]::Empty }
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
