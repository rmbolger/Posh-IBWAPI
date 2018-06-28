#Requires -Version 3.0

# set the user module path based on edition and platform
if ('PSEdition' -notin $PSVersionTable.Keys -or $PSVersionTable.PSEdition -eq 'Desktop') {
    $installpath = "$($env:USERPROFILE)\Documents\WindowsPowerShell\Modules"
} else {
    if ($IsWindows) {
        $installpath = "$($env:HOME)\Documents\PowerShell\Modules"
    } else {
        $installpath = "$($env:HOME)/.local/share/powershell/Modules"
    }
}

# create user-specific modules folder if it doesn't exist
New-Item -ItemType Directory -Force -Path $installpath | out-null

if ([String]::IsNullOrWhiteSpace($PSScriptRoot)) {
    # likely running from online

    # GitHub now requires TLS 1.2
    # https://blog.github.com/2018-02-23-weak-cryptographic-standards-removed/
    $currentMaxTls = [Math]::Max([Net.ServicePointManager]::SecurityProtocol.value__,[Net.SecurityProtocolType]::Tls.value__)
    $newTlsTypes = [enum]::GetValues('Net.SecurityProtocolType') | Where-Object { $_ -gt $currentMaxTls }
    $newTlsTypes | ForEach-Object {
        [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor $_
    }

    # download and extract
    $webclient = New-Object System.Net.WebClient
    $url = 'https://github.com/rmbolger/Posh-IBWAPI/archive/master.zip'
    Write-Host "Downloading latest version of Posh-IBWAPI from $url" -ForegroundColor Cyan
    $file = Join-Path ([system.io.path]::GetTempPath()) 'Posh-IBWAPI.zip'
    $webclient.DownloadFile($url,$file)
    Write-Host "File saved to $file" -ForegroundColor Green

    # try to use Expand-Archive if it exists, otherwise assume Desktop
    # edition and use COM
    Write-Host "Uncompressing the Zip file to $($installpath)" -ForegroundColor Cyan
    if (Get-Command Expand-Archive -EA SilentlyContinue) {
        Expand-Archive $file -DestinationPath $installpath
    } else {
        $shell_app=new-object -com shell.application
        $zip_file = $shell_app.namespace($file)
        $destination = $shell_app.namespace($installpath)
        $destination.Copyhere($zip_file.items(), 0x10)
    }

    Write-Host "Removing any old copy" -ForegroundColor Cyan
    Remove-Item "$installpath\Posh-IBWAPI" -Recurse -Force -EA SilentlyContinue
    Write-Host "Renaming folder" -ForegroundColor Cyan
    Copy-Item "$installpath\Posh-IBWAPI-master\Posh-IBWAPI" $installpath -Recurse -Force
    Remove-Item "$installpath\Posh-IBWAPI-master" -recurse -confirm:$false
    Import-Module -Name Posh-IBWAPI -Force
} else {
    # running locally
    Remove-Item "$installpath\Posh-IBWAPI" -Recurse -Force -EA SilentlyContinue
    Copy-Item "$PSScriptRoot\Posh-IBWAPI" $installpath -Recurse -Force
    # force re-load the module (assuming you're editing locally and want to see changes)
    Import-Module -Name Posh-IBWAPI -Force
}
Write-Host 'Module has been installed' -ForegroundColor Green

Get-Command -Module Posh-IBWAPI
