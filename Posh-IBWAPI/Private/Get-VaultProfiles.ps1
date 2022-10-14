function Get-VaultProfiles {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [Collections.IDictionary]$VaultConfig
    )

    $vaultCfg = $VaultConfig

    # attempt to unlock the vault if necessary
    if ($vaultCfg.Password) {
        Write-Debug "Unlocking vault $($vaultCfg.Name)"
        Unlock-SecretVault -Name $vaultCfg.Name -Password $vaultCfg.Password
    }

    $vaultProfiles = @{}

    # grab the current set of raw vault profiles
    $nameSearch = $vaultCfg.Template.Replace('{0}','*')
    Get-SecretInfo -Vault $vaultCfg.Name -Name $nameSearch | ForEach-Object {

        # parse the profile name from the secret name and template
        $reProfName = [regex]::Escape($vaultCfg.Template).Replace('\{0}','(.*)')
        if ($_.Name -match $reProfName) {
            $profName = $matches[1]
        } else {
            $PSCmdlet.WriteError([Management.Automation.ErrorRecord]::new(
                "Unable to parse profile name from secret name '$($_.Name)' with template '$($vaultCfg.Template)'",
                $null, [Management.Automation.ErrorCategory]::InvalidData, $null
            ))
            # skip to the next secret
            return
        }

        # parse the raw profile data
        $profRaw = $_ | Get-Secret -AsPlainText | ConvertFrom-Json

        # add it to the hashtable
        $vaultProfiles.$profName = $profRaw

    }

    $vaultProfiles
}
