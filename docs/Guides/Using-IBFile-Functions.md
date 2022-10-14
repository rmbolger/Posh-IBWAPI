title: Using IBFile Functions

# Using IBFile Functions

The Infoblox WAPI has long supported the `fileop` object type which has a bunch of functions associated with it for uploading and download data to and from the appliance (database backups, certificate uploads, etc). While it is possible to use these upload and download functions via `Invoke-IBFunction`, the process is tedious and requires multiple steps. Uploads are particularly difficult because older versions of PowerShell don't support multipart form data uploads in the native web cmdlets. So you're either forced to upgrade your PowerShell version to 6.1+ or delve into lower level .NET functionality to do the actual file upload step. To alleviate these hassles, `Receive-IBFile` and `Send-IBFile` were added in Posh-IBWAPI 2.0. Their goal is to turn uploading or downloading data from Infoblox into a single function call.

NOTE: The examples in this guide were written against WAPI 2.10 (NIOS 8.4). If your grid is on an earlier version, functions available and their arguments might be different. Check the docs for your version if you have problems.

## Receive-IBFile

Let's start with downloading data because it's usually easier and probably more common. Here's the function syntax via `Get-Help`

```
SYNTAX
    Receive-IBFile [-FunctionName] <String> [-OutFile] <String> [[-FunctionArgs]
    <Hashtable>] [[-ObjectRef] <String>] [-OverrideTransferHost] [[-WAPIHost]
    <String>] [[-WAPIVersion] <String>] [[-Credential] <PSCredential>]
    [-SkipCertificateCheck] [[-ProfileName] <String>] [<CommonParameters>]
```

`FunctionName` and `OutFile` are the only two required parameters. But most WAPI functions will also have at least one input field you need to specify with `FunctionArgs`. `ObjectRef` is set to `fileop` by default because that's where most of the upload/download functions live. But depending on your WAPI version, there are a few tied to other object types as well. So if you're using one of those, you'd need to specify that parameter.

We want to download a grid database backup using fileop's `getgriddata` function. To quickly review the docs for the function, run this to open a browser to the fileop object type:

```powershell
Get-IBSchema fileop -LaunchHTML
```

Alternatively, you could query the function details directly. But they're usually not quite as detailed as the HTML version. It's also nice to have a browser window open for reference, but here's how to do it anyway:

```powershell
Get-IBSchema fileop -Functions getgriddata -Detail -NoFields
```

The only thing you should need to care about for a download function are the inputs. To download a basic grid database backup with no discovery data (the default), we only need a single argument:

```powershell
$fArgs = @{ type = 'BACKUP' }
```

Now we just call the function and we're done. Obviously, the time it takes is going to vary based on your environment and the size of your grid. It can also be significantly be faster when using PowerShell 7+ (more on that later).

```powershell
Receive-IBFile -FunctionName getgriddata -OutFile .\backup.tar.gz -FunctionArgs $fArgs
```

## Send-IBFile

Uploading data isn't that much different than downloading. Here's the function syntax:

```
SYNTAX
    Send-IBFile [-FunctionName] <String> [-Path] <String> [-FunctionArgs
    <Hashtable>] [-ObjectRef <String>] [-OverrideTransferHost] [-WAPIHost <String>]
    [-WAPIVersion <String>] [-Credential <PSCredential>] [-SkipCertificateCheck]
    [-ProfileName <String>] [<CommonParameters>]
```

`FunctionName` is still required. `Path` will be the path to the file you're uploading and is required. `FunctionArgs` will hold the input fields for the WAPI function with one exception. Most upload functions have a mandatory `token` field which is returned by the `uploadinit` function. You can ignore this requirement because `Send-IBFile` will handle it for you. `ObjectRef` is still set to `fileop` by default. So you can ignore it unless your upload function is tied to another object type.

In this example, we're going to upload a new trusted CA certificate to the grid using fileop's `uploadcertificate` function. This is useful for environments running an internal PKI infrastructure, particularly when using Microsoft Management and connecting to servers via LDAPS (LDAP over SSL). Any valid CA certificate will suffice for this example as long as it hasn't already been imported into your grid. For my own test, I'm using the [Let's Encrypt](https://letsencrypt.org) CA's self-signed root, [ISRG Root X1](https://letsencrypt.org/certs/isrgrootx1.pem.txt).

Uploading a CA certificate via `uploadcertificate` requries a single input field, `certificate_usage`. We can ignore `token` because it is automatically handled by the function and we can ignore `member` because CA certificates are applied grid-wide.

```powershell
$fArgs = @{ certificate_usage = 'EAP_CA' }
```

Now we just call the function and we're done.

```powershell
Send-IBFile -FunctionName uploadcertificate -Path .\myca.pem -FunctionArgs $fArgs
```

If you navigate to `Grid - Grid Manager - Members` in the web UI and click the `Certificates` button in the toolbar, you should see your freshly uploaded CA certificate in the list. Feel free to delete it, if this was just a test certificate.


## Regarding Transfer Speeds

Historically, Windows PowerShell was not the speediest tool for uploading or downloading large files via the web cmdlets. But there have been significant performance improvements in PowerShell 7+, particularly around the web cmdlets. So if you have the choice, definitely choose the latest verion of PowerShell over legacy Windows PowerShell as this will directly impact the performance of Posh-IBWAPI. As a completely non-scientific example, a 1 GB file took roughly 23 **seconds** to downloaded in PowerShell Core 7.2 on my machine using `Invoke-WebRequest`. The same file downloaded on the same system in Windows PowerShell 5.1 took roughly 10 **minutes**. That's about a **2600%** speed increase just for using a newer version of PowerShell.
