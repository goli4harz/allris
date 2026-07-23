[CmdletBinding(SupportsShouldProcess)]
param(
    [string]$N8nBaseUrl = 'http://172.16.1.14:5678',
    [string]$ApiKey = $env:N8N_API_KEY,
    [string]$DataTableId = 'hBLqpqeVEojPpOJl',
    [switch]$Apply
)

$ErrorActionPreference = 'Stop'

if ([string]::IsNullOrWhiteSpace($ApiKey)) {
    throw 'N8N_API_KEY beziehungsweise -ApiKey fehlt.'
}

$base = $N8nBaseUrl.TrimEnd('/')
$columnsUri = "$base/api/v1/data-tables/$DataTableId/columns"
$headers = @{
    'X-N8N-API-KEY' = $ApiKey
    'Content-Type' = 'application/json'
    'Cache-Control' = 'no-cache'
}
$requiredColumns = @(
    [ordered]@{ name = 'last_error_code'; type = 'string' }
    [ordered]@{ name = 'last_error_message'; type = 'string' }
    [ordered]@{ name = 'last_error_stage'; type = 'string' }
    [ordered]@{ name = 'last_error_at'; type = 'string' }
    [ordered]@{ name = 'retry_count'; type = 'number' }
    [ordered]@{ name = 'next_retry_at'; type = 'string' }
)

function Get-LiveColumns {
    $tables = Invoke-RestMethod -Method Get -Uri "$base/api/v1/data-tables?limit=250" -Headers $headers
    $table = @($tables.data | Where-Object id -eq $DataTableId)
    if ($table.Count -ne 1) {
        throw "Data Table $DataTableId fehlt oder ist nicht eindeutig."
    }
    return @($table[0].columns)
}

Write-Host "Prüfe Data Table $DataTableId unter $base ..."
$existing = @(Get-LiveColumns)
$existingNames = @($existing | ForEach-Object { [string]$_.name })
$missing = @($requiredColumns | Where-Object { $_.name -notin $existingNames })

if ($missing.Count -eq 0) {
    Write-Host 'Schema ist bereits vollständig. Keine Änderung nötig.' -ForegroundColor Green
    exit 0
}

Write-Host "Fehlende Spalten ($($missing.Count)):" -ForegroundColor Yellow
$missing | ForEach-Object { Write-Host "  - $($_.name) [$($_.type)]" }

if (-not $Apply) {
    Write-Host ''
    Write-Host 'Nur Vorschau. Zum Anlegen erneut mit -Apply starten.'
    exit 0
}

foreach ($column in $missing) {
    $description = "$($column.name) [$($column.type)]"
    if ($PSCmdlet.ShouldProcess("Data Table $DataTableId", "Spalte $description anlegen")) {
        $body = $column | ConvertTo-Json -Compress
        $created = Invoke-RestMethod -Method Post -Uri $columnsUri -Headers $headers -Body $body
        Write-Host "Angelegt: $($created.name) [$($created.type)]" -ForegroundColor Green
    }
}

$verified = @(Get-LiveColumns)
$verifiedNames = @($verified | ForEach-Object { [string]$_.name })
$stillMissing = @($requiredColumns | Where-Object { $_.name -notin $verifiedNames })

if ($stillMissing.Count -gt 0) {
    throw "Schema unvollständig. Es fehlen: $(($stillMissing.name) -join ', ')"
}

Write-Host 'Schema erfolgreich vervollständigt und geprüft.' -ForegroundColor Green
