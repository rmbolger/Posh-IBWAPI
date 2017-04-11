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