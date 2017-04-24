function Format-Columns {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true,ValueFromPipeline=$true)]
        [PsObject[]]$InputObject,
        [Object]$Property,
        [int]$Column,
        [int]$MaxColumn,
        [switch]$Autosize,
        [System.ConsoleColor]$ForegroundColor,
        [System.ConsoleColor]$BackgroundColor
    )
    
    Begin   { $values = @() }
    Process { $values += $InputObject }
    End {
        function ProcessValues {
            $ret = $values
            $p = $Property
            if ($p -is [Hashtable]) {
                $exp = $p.Expression
                if ($exp) {
                    if ($exp -is [string])          { $ret = $ret | % { $_.($exp) } }
                    elseif ($exp -is [scriptblock]) { $ret = $ret | % { & $exp $_} }
                    else                            { throw 'Invalid Expression value' }
                }
                if ($p.FormatString) {
                    if ($p.FormatString -is [string]) {    $ret = $ret | % { $p.FormatString -f $_ } }
                    else {                              throw 'Invalid format string' }
                }
            }
            elseif ($p -is [scriptblock]) { $ret = $ret | % { & $p $_} }
            elseif ($p -is [string]) {      $ret = $ret | % { $_.$p } }
            elseif ($p -ne $null) {         throw 'Invalid -property type' }
            # in case there were some numbers, objects, etc., convert them to string
            $ret | % { $_.ToString() }
        }
        function Base($i) { [Math]::Floor($i) }
        function Max($i1, $i2) {  [Math]::Max($i1, $i2) }
        if (!$Column) { $Autosize = $true }
        $values = ProcessValues
        
        $valuesCount = @($values).Count
        if ($valuesCount -eq 1) {
            Write-Host $values -ForegroundColor $ForegroundColor -BackgroundColor $BackgroundColor
            return
        }
        
        # from some reason the console host doesn't use the last column and writes to new line
        $consoleWidth          = $host.ui.RawUI.maxWindowSize.Width - 1
        $gutterWidth = 2
            
        # get length of the longest string
        $values | % -Begin { [int]$maxLength = -1 } -Process { $maxLength = Max $maxLength $_.Length }
        
        # get count of columns if not provided
        if ($Autosize) {
            $Column         = Max (Base ($consoleWidth/($maxLength+$gutterWidth))) 1
            $remainingSpace = $consoleWidth - $Column*($maxLength+$gutterWidth);
            if ($remainingSpace -ge $maxLength) { 
                $Column++ 
            }
            if ($MaxColumn -and $MaxColumn -lt $Column) {
                $Column = $MaxColumn
            }
        }
        $countOfRows       = [Math]::Ceiling($valuesCount / $Column)
        $maxPossibleLength = Base ($consoleWidth / $Column)
        
        # cut too long values, considers count of columns and space between them
        $values = $values | % {
            if ($_.length -gt $maxPossibleLength) { $_.Remove($maxPossibleLength-2) + '..' }
            else { $_ }
        }
        
        #add empty values so that the values fill rectangle (2 dim array) without space
        if ($Column -gt 1) {
            $values += (@('') * ($countOfRows*$Column - $valuesCount))
        }
        # in case there is only one item, make it array
        $values = @($values)
        <#
        now we have values like this: 1, 2, 3, 4, 5, 6, 7, ''
        and we want to display them like this:
        1 3 5 7
        2 4 6 ''
        #>
        
        $formatString = (1..$Column | %{ "{$($_-1),-$maxPossibleLength}" }) -join ''

        1..$countOfRows | % {
            $r    = $_-1
            $line = @(1..$Column | %{ $values[$r + ($_-1)*$countOfRows]} )
            Write-Host "$($formatString -f $line)".PadRight($consoleWidth,' ') -BackgroundColor $BackgroundColor -ForegroundColor $ForegroundColor
        }
    }

    <#
    .SYNOPSIS
        Formats incoming data to columns.
    .DESCRIPTION
        It works similarly as Format-Wide but it works vertically. Format-Wide outputs the data row by row, but Format-Columns outputs them column by column.
    .PARAMETER Property
        Name of property to get from the object.
        It may be 
            -- string - name of property.
            -- scriptblock
            -- hashtable with keys 'Expression' (value is string=property name or scriptblock)
                and 'FormatString' (used in -f operator)
    .PARAMETER Column
        Count of columns
    .PARAMETER Autosize
        Determines if count of columns is computed automatically.
    .PARAMETER MaxColumn
        Maximal count of columns if Autosize is specified
    .PARAMETER InputObject
        Data to display
    .EXAMPLE
        1..150 | Format-Columns -Autosize
    .EXAMPLE 
        Format-Columns -Col 3 -Input 1..130
    .EXAMPLE
        Get-Process | Format-Columns -prop @{Expression='Handles'; FormatString='{0:00000}'} -auto
    .EXAMPLE
        Get-Process | Format-Columns -prop {$_.Handles} -auto
    .NOTES
        Name: Get-Columns
        Author: stej, http://twitter.com/stejcz
        Site: http://www.leporelo.eu/blog.aspx?id=powershell-formatting-format-wide-rotated-to-format-columns
        Lastedit: 2017-04-24
        Version 0.3 - 2017-04-24
        - added ForegroundColor and BackgroundColor
        Version 0.2 - 2010-01-14
        - added MaxColumn
        - fixed bug - displaying collection of 1 item was incorrect
        Version 0.1 - 2010-01-06
    #>
}