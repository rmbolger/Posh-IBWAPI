#Requires -Version 3.0

# create user-specific modules folder if it doesn't exist
$targetondisk = "$($env:USERPROFILE)\Documents\WindowsPowerShell\Modules"
New-Item -ItemType Directory -Force -Path $targetondisk | out-null

if ([String]::IsNullOrWhiteSpace($PSScriptRoot)) {
    # likely running from online, so download and extract
    $webclient = New-Object System.Net.WebClient
    $url = 'https://github.com/rmbolger/Posh-IBWAPI/archive/master.zip'
    Write-Host "Downloading latest version of Posh-IBWAPI from $url" -ForegroundColor Cyan
    $file = "$($env:TEMP)\Posh-IBWAPI.zip"
    $webclient.DownloadFile($url,$file)
    Write-Host "File saved to $file" -ForegroundColor Green
    $shell_app=new-object -com shell.application
    $zip_file = $shell_app.namespace($file)
    Write-Host "Uncompressing the Zip file to $($targetondisk)" -ForegroundColor Cyan
    $destination = $shell_app.namespace($targetondisk)
    $destination.Copyhere($zip_file.items(), 0x10)
    Write-Host "Renaming folder" -ForegroundColor Cyan
    Copy-Item "$($targetondisk)\Posh-IBWAPI-master\Posh-IBWAPI" $targetondisk -Recurse -Force
    Remove-Item "$($targetondisk)\Posh-IBWAPI-master" -recurse -confirm:$false
    Import-Module -Name Posh-IBWAPI
} else {
    # running locally
    Copy-Item "$PSScriptRoot\Posh-IBWAPI" $targetondisk -Recurse -Force
    # force re-load the module (assuming you're editing locally and want to see changes)
    Import-Module -Name Posh-IBWAPI -Force
}
Write-Host 'Module has been installed' -ForegroundColor Green

Get-Command -Module Posh-IBWAPI