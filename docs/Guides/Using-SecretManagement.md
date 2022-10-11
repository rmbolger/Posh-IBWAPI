# Using SecretManagement

Prior to Posh-IBWAPI 4.0, saved connection profiles were stored in JSON config file on the local filesystem. That is still the default in 4.0, but you may now alternatively utilize the Microsoft [SecretManagement](https://devblogs.microsoft.com/powershell/secretmanagement-and-secretstore-are-generally-available/) module to store connection profiles in a variety of local, on-prem, and cloud secret stores using supported [vault extensions](https://www.powershellgallery.com/packages?q=Tags%3A%22SecretManagement%22).

!!! warning
    Some vault extensions are read-only and don't allow for creation of new secrets. While it is technically possible to use these extensions with Posh-IBWAPI by pre-creating the necessary secrets, it is not recommended. Calls to `Set-IBConfig` and `Remove-IBConfig` will fail and likely leave the module in an inconsistent state.

## Prerequisites

In order to use the SecretManagement feature, you must install both the [Microsoft.PowerShell.SecretManagement](https://www.powershellgallery.com/packages/Microsoft.PowerShell.SecretManagement/) module and an appropriate vault extension module to interface with your preferred secret store.

You will also need to register a new vault and make note of the vault name. It will be provided to Posh-IBWAPI using the `IBWAPI_VAULT_NAME` environment variable.

### Vault Password

Some vaults can be configured with a password such that retrieving a secret requires first unlocking the vault with the password. In order to use a vault with Posh-IBWAPI, you have three options.

- Configure the vault so a password is not required.
- Provide the vault password using the `IBWAPI_VAULT_PASS` environment variable.
- Prior to importing the module, unlock or pre-authenticate to the vault so Posh-IBWAPI can make calls like `Set-Secret` and `Get-Secret` without error.

### Secret Names and Customization

Each connection profile will be stored as its own secret in the vault using the following default naming convention:

> `poshibwapi-{0}`

The `{0}` is replaced with the profile name passed to `Set-IBConfig`.

You may optionally create an environment variable called `IBWAPI_VAULT_SECRET_TEMPLATE` to override the default template. The new value should include `{0}` somewhere in the string, but will be appended to the end if it does not exist.

!!! warning
    Be aware that some vaults have restrictions on the characters allowed in a secret name. In particular, Azure KeyVault is very restrictive and only allows letters, numbers, and the hyphen `-` character.

## Using a Vault

### Enable Vault Profile Storage

To enable vault profile storage, make sure the environment variables are set properly based on the prerequisites listed above before importing the module. If you set them after the module is already loaded or need to change the values, you will need to force re-load the module for them to take effect.

```powershell
Import-Module Posh-IBWAPI -Force
```

If there is a problem accessing the vault during import, an error is thrown and the module falls back to storing connection profiles on the filesystem.

### Disable Vault Key Storage

To disable vault profile storage, just remove the vault related environment variables and force re-load the module. There is currently no way to migrate local profiles to vault profiles or the other way around. This may be added in a future release.

## Additional Considerations

### Azure KeyVault

Azure KeyVault has deprecated the ability to have vaults that allow immediate secret removal. "soft-delete" is now the default mode and will soon be mandatory which makes it so that deleted secrets are kept in a sort of recycle-bin until their configurable retention period expires.

If you attempt to create a new secret using the SecretManagement module with a name that matches a soft-deleted secret, the call will fail. This means certain profile management actions within Posh-IBWAPI may fail like removing a connection profile and then re-creating it later or renaming one and then renaming it back.

While it is possible to purge soft-deleted secrets, it is not possible using only the SecretManagement module. I have opened [feature request #19733](https://github.com/Azure/azure-powershell/issues/19733) to address this with the Azure PowerShell team.

### Sharing Configs and Vaults

When using centralized vaults, it is possible to point multiple instances of Posh-IBWAPI to the same vault and effectively share the config. However, keep in mind that if one instances changes a profile or changes the active profile, the change won't be seen by the other instances unless they force re-load the module or load a new instance.
