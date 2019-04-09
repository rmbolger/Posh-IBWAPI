function New-MultipartFileContent {
    [OutputType('System.Net.Http.MultipartFormDataContent')]
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [System.IO.FileInfo]$File,
        [string]$HeaderName='file'
    )

    # Need to load System.Net.Http on Desktop edition
    if (-not $PSEdition -or $PSEdition -eq 'Desktop') {
        Add-Type -AssemblyName System.Net.Http
    }

    # build the header and make sure to include quotes around Name
    # and FileName like https://github.com/PowerShell/PowerShell/pull/6782)
    $fileHeader = [System.Net.Http.Headers.ContentDispositionHeaderValue]::new('form-data')
    $fileHeader.Name = "`"$HeaderName`""
    $fileHeader.FileName = "`"$($File.Name)`""

    # build the content
    $fs = [System.IO.FileStream]::new($File.FullName, [System.IO.FileMode]::Open)
    $fileContent = [System.Net.Http.StreamContent]::new($fs)
    # $fileBytes = [System.IO.File]::ReadAllBytes($File.FullName)
    # $fileContent = [System.Net.Http.ByteArrayContent]::new($fileBytes)
    $fileContent.Headers.ContentDisposition = $fileHeader
    $fileContent.Headers.ContentType = [System.Net.Http.Headers.MediaTypeHeaderValue]::Parse('application/octet-stream')

    # add it to a new MultipartFormDataContent object
    $multipart = [System.Net.Http.MultipartFormDataContent]::new()
    $multipart.Add($fileContent)

    # get rid of the quotes around the boundary value
    # https://github.com/PowerShell/PowerShell/issues/9241
    $boundary = $multipart.Headers.ContentType.Parameters | Where-Object { $_.Name -eq 'boundary' }
    $boundary.Value = $boundary.Value.Trim('"')

    return @(,$multipart)
}
