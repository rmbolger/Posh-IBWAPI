function Word-Wrap {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$True,ValueFromPipeline=$True,ValueFromPipelineByPropertyName=$True)]
        [string[]]$Text,
        [int]$MaxWidth=$Host.UI.RawUI.BufferSize.Width,
        [int]$Indent,
        [switch]$PadMax
    )

    Process {

        # setup our return array
        $retLines = @()

        if ($Indent) { $MaxWidth -= $Indent }

        foreach ($origString in $Text) {
            Write-Debug "Top length $($origString.Length)"

            # because we may be indenting, we need to care about embedded NewLine
            # characters and insert the indent for each one
            foreach ($line in $origString.Split([Environment]::NewLine)) {
                Write-Debug "new outer line"

                while ($line.Length -gt $MaxWidth) {
                    $newLine = ''

                    # copy a maxWidth+1 chunk
                    $chunk = $line.Substring(0,$MaxWidth+1)
                    $lastSpaceIndex = $chunk.LastIndexOf(' ')
                    Write-Debug "chunk length $($chunk.length) and space index $lastSpaceIndex"

                    if ($lastSpaceIndex -le 0) {
                        # no natural spaces to split, so just split on max width
                        $lastSpaceIndex = $MaxWidth
                    }

                    # grab the piece we need, pad and indent if necessary,
                    # and add it to the output
                    $newLine = $chunk.Substring(0,$lastSpaceIndex)
                    if ($PadMax) { $newLine = $newLine.PadRight($MaxWidth) }
                    if ($Indent) { $newLine = "$(' ' * $Indent)$newLine" }
                    $retLines += $newLine

                    # remove the piece from current line
                    $line = $line.Substring($lastSpaceIndex + 1)
                }

                Write-Debug "last chunk length $($line.length)"
                # pad and indent if necessary and add the last piece to the output
                if ($PadMax) { $line = $line.PadRight($MaxWidth) }
                if ($Indent) { $line = "$(' ' * $Indent)$line" }
                $retLines += $line
            }

        }
        $retLines
    }

    <#
    .SYNOPSIS
        Attempts to wrap a string or array of strings at the word boundary given a maximum width.

    .PARAMETER Text
        A string or an array of strings.

    .PARAMETER MaxWidth
        The maximum characters per line.

    .PARAMETER Indent
        The number of characters to indent each line.

    .PARAMETER PadMax
        If set, each line will be padded with spaces on the right with enough to reach -MaxWidth.

    .EXAMPLE
        Word-Wrap $longString

        Word wrap $longString to the max console width.

    .EXAMPLE
        $longString | Word-Wrap -max 100 -indent 4 -pad

        Word wrap $longString to 100 characters with a 4 character indent and right padding.
    #>
}