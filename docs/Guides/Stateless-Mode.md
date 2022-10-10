title: Stateless Mode

# Stateless Mode

Particularly in cloud environments, being able to use the module without needing to run an explicit configuration command like `Set-IBConfig` can be very useful. Posh-IBWAPI 4.0 now allows you to do that by specifying configuring the properties of a typical connection profile as environment variables. If the module is imported and sees these environment variables, they will override any local config file that may exist.

!!! note
    The environment variable based profile will also override any SecretManagement related environment variables which are also new in 4.0

## Supported Environment Variables

The rules for these values mimic the rules for the equivalent parameters in `Set-IBConfig` except the Credential is split out into separate username and password values.

| Name                 | Example        | Notes |
| ----                 | -------        | ----- |
| IBWAPI_HOST          | gm.example.com | (Required) This can be an FQDN or IP address |
| IBWAPI_VERSION       | 2.12.1         | (Required) A valid WAPI version string |
| IBWAPI_USERNAME      | admin          | (Required) The account username |
| IBWAPI_PASSWORD      | infoblox       | (Required) The plaintext password |
| IBWAPI_SKIPCERTCHECK | False          | (Optional) False if not defined, empty, or equal to 'False', 'No', or '0' |

The values are read during module import. So if you set them after the module is already loaded or need to change the values, you will need to force re-load the module for them to take effect.

```powershell
Import-Module Posh-IBWAPI -Force
```

You'll know it's working if you run `Get-IBConfig` and see a profile called `ENV` with your details similar to this:

```ps1con
ProfileName WAPIHost       WAPIVersion CredentialUser SkipCertificateCheck
----------- --------       ----------- -------------- --------------------
ENV         gm.example.com 2.12.1      admin          False
```

Also a warning will be thrown if you attempt to use `Set-IBConfig` or `Remove-IBConfig` while an environment variable based profile is active.
