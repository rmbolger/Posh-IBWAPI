# Observations: Invoke-RestMethod and authentication

* Using both -WebSession and -SessionVariable in the same call is not supported and will generate an exception.
* The `WebRequestSession` object set by `-SessionVariable` contains a copy of the `-Credential` used and the `ibapauth` cookie returned from Infoblox.
* When the session expires, the embedded credential will automatically be used to re-authenticate on the next call and update cookie in the session object.
* Instead of using `-SessionVariable`, it is possible to pre-create a `WebRequestSession` object with embedded credentials and use that with `-WebSession` instead of making a separate call with `-SessionVariable` first. It will automatically authenticate the same way it does if the login cookie had expired.

```powershell
   $session = New-Object Microsoft.PowerShell.Commands.WebRequestSession
   $session.Credentials = (Get-Credential).GetNetworkCredential()
   Invoke-RestMethod -Uri "http://example.com" -WebSession $session
```

* It is possible to use both `-Credential` and `-WebSession` in the same call. If the `ibapauth` cookie in the session object is still valid, that will be used even if the explicit credential object is a different user. If there is no cookie or the cookie is expired, the explicit credential object will override any credential embedded in the session object.

Because the functions in this module are largely just wrapping Invoke-RestMethod, all of the observations listed above apply to this module's functions that take the same parameters.

# Observations: Disabling Certificate Validation

There is unfortunately no native support in `Invoke-RestMethod` (or any related cmdlet) for per-call disabling of certificate validation. Validation logic is controlled globally at the .NET level on a per-session basis in [System.Net.ServicePointManager](https://msdn.microsoft.com/en-us/library/system.net.servicepointmanager(v=vs.110).aspx). In order to mimic a per-call disable flag, we're essentially disabling cert validation globally just long enough to make our call to `Invoke-RestMethod` and then setting it back to the default functionality.

However, the `ServicePointManager` seems to cache the validation results for each base URL. The result is that for a short period of time (minutes), cert validation will continue to appear to be disabled when making calls against the same WAPI endpoint even though cert validation is technically turned back on.

There may be a way to shorten the cache duration by changing the value of [ServicePointManager.MaxServicePointIdleTime](https://msdn.microsoft.com/en-us/library/system.net.servicepointmanager.maxservicepointidletime(v=vs.110).aspx). But even setting it to 0 doesn't remove the cached validation immediately. There's still a delay likely waiting for the idle object to be garbage collected.

For the time being, we're going to leave `MaxServicePointIdleTime` alone as it's likely an extreme edge case that someone would need to disable cert validation for a single call and then turn it back on for the same WAPI endpoint in quick succession. Most of the people who care about this feature are running Infoblox with the default self-signed certificate and will just choose to always have certificate validation disabled.

UPDATE: The version of Invoke-RestMethod included in Powershell Core 6.0 includes a -SkipCertificateCheck parameter which should resolve this issue at least for Core edition users. Hopefully Microsoft will back port those changes into Desktop edition eventually.
