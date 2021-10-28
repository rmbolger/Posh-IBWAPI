function Register-ArgCompleters {
    [CmdletBinding()]
    param()

    # setup the argument completers
    # https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/register-argumentcompleter

    # these only work in PowerShell 5+, so just return if we can't use them
    if (-not (Get-Command 'Register-ArgumentCompleter' -ErrorAction SilentlyContinue)) {
        return
    }

    # ProfileName
    $ProfileNameCompleter = {
        param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameter)

        $names = @((Get-Profiles).Keys)
        $names | Where-Object { $_ -like "$wordToComplete*" } | ForEach-Object {
            [Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', $_)
        }
    }
    $ProfileNameCommands = @(
        'Get-IBConfig'
        'Get-IBObject'
        'Get-IBSchema'
        'Invoke-IBFunction'
        'New-IBObject'
        'Receive-IBFile'
        'Remove-IBConfig'
        'Remove-IBObject'
        'Send-IBFile'
        'Set-IBConfig'
        'Set-IBObject'
    )
    Register-ArgumentCompleter -CommandName $ProfileNameCommands -ParameterName 'ProfileName' -ScriptBlock $ProfileNameCompleter

    # ObjectType
    $ObjectTypeCompleter = {
        param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameter)

        # we need the call variables so we know what set of object types to filter from
        try { $opts = Initialize-CallVars @fakeBoundParameter -Debug:$false } catch { return }

        # return early if we don't have cached schema info matching the call variables
        if (-not $script:Schemas[$opts.WAPIHost] -or
            -not $script:Schemas[$opts.WAPIHost][$opts.WAPIVersion])
        {
            return
        }

        $objectTypes = $script:Schemas[$opts.WAPIHost][$opts.WAPIVersion]

        $objectTypes | Where-Object { $_ -like "$wordToComplete*" } | ForEach-Object {
            [Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', $_)
        }
    }
    Register-ArgumentCompleter -CommandName 'Get-IBObject','Get-IBSchema','New-IBObject' -ParameterName 'ObjectType' -ScriptBlock $ObjectTypeCompleter

}
