function Get-VaultConfig {
    [CmdletBinding()]
    param(
        [switch]$Refresh
    )

    # unless we're refreshing, just return the in memory config if it exists
    if (-not $Refresh) {
        return $script:VaultConfig
    }

    # Return nothing unless the minimum vault components are defined and working.

    # check for non-empty vault name
    if ([string]::IsNullOrWhiteSpace($env:IBWAPI_VAULT_NAME)) {
        return
    }

    # check for the necessary SecretManagement commands
    if (-not (Get-Command 'Unlock-SecretVault' -EA Ignore) -or
        -not (Get-Command 'Get-Secret' -EA Ignore) )
    {
        $PSCmdlet.WriteError([Management.Automation.ErrorRecord]::new(
            "Unable to use Vault profiles. Commands associated with SecretManagement module not found. Make sure Microsoft.PowerShell.SecretManagement is installed and accessible.",
            $null, [Management.Automation.ErrorCategory]::ObjectNotFound, $null
        ))
        return
    }

    # create bare minimum vault config
    $vaultCfg = @{
        Name = $env:IBWAPI_VAULT_NAME
        Template = 'poshibwapi-{0}'
    }

    # check for unlock password
    if (Test-NonEmptyString $env:IBWAPI_VAULT_PASS) {
        $vaultCfg.Password = ConvertTo-SecureString $env:IBWAPI_VAULT_PASS -AsPlainText -Force

        # Make sure it works. Unlocking a vault should always work even if it's
        # already unlocked.
        try {
            Unlock-SecretVault -Name $vaultCfg.Name -Password $vaultCfg.Password -EA Stop
        }
        catch {
            $PSCmdlet.WriteError($_)
            return
        }
    }

    # check for secret template override
    if (Test-NonEmptyString $env:IBWAPI_VAULT_SECRET_TEMPLATE) {

        if ($env:IBWAPI_VAULT_SECRET_TEMPLATE -like '*{0}*') {
            Write-Verbose "Overriding vault secret template with '$($env:IBWAPI_VAULT_SECRET_TEMPLATE)'"
            $vaultCfg.Template = $env:IBWAPI_VAULT_SECRET_TEMPLATE
        }
        else {
            # they forgot to include the {0}, so we'll treat the current value like a prefix
            Write-Verbose "Overriding vault secret template with '$($env:IBWAPI_VAULT_SECRET_TEMPLATE){0}'"
            $vaultCfg.Template = "$($env:IBWAPI_VAULT_SECRET_TEMPLATE){0}"
        }
    }

    # test vault access
    if (-not (Test-SecretVault -Name $vaultCfg.Name)) {
        # the Test function should emit its own error(s) if it failed
        # so just return
        return
    }

    return $vaultCfg

}
