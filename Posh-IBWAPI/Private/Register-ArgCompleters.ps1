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
            # "::new()" syntax ok here because we'll only reach it on PS5+
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

}
