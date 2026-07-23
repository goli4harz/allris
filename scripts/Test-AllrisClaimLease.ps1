[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter(Mandatory)]
    [string]$VorgangKey,
    [string]$N8nBaseUrl = 'http://172.16.1.14:5678',
    [string]$ApiKey = $env:N8N_API_KEY,
    [string]$DataTableId = 'hBLqpqeVEojPpOJl',
    [switch]$Apply
)

$ErrorActionPreference = 'Stop'

if ([string]::IsNullOrWhiteSpace($ApiKey)) {
    throw 'N8N_API_KEY beziehungsweise -ApiKey fehlt.'
}

if (-not $Apply) {
    Write-Host "Nur Vorschau: Doppelclaim-Test für '$VorgangKey'." -ForegroundColor Yellow
    Write-Host 'Mit -Apply wird der Claim kurz gesetzt, konkurrierend geprüft und im finally-Block freigegeben.'
    exit 0
}

$rowsUri = "$($N8nBaseUrl.TrimEnd('/'))/api/v1/data-tables/$DataTableId/rows"
$headers = @{ 'X-N8N-API-KEY' = $ApiKey }
$owner1 = "claim-test-owner-1-$([guid]::NewGuid().ToString('N'))"
$owner2 = "claim-test-owner-2-$([guid]::NewGuid().ToString('N'))"
$acquired = $false

function Invoke-RowUpdate {
    param(
        [hashtable]$Filter,
        [hashtable]$Data
    )

    $payload = @{
        filter = $Filter
        data = $Data
        returnData = $true
        dryRun = $false
    } | ConvertTo-Json -Depth 10 -Compress

    return @(Invoke-RestMethod -Method Patch -Uri "$rowsUri/update" `
        -Headers $headers -ContentType 'application/json; charset=utf-8' `
        -Body ([Text.Encoding]::UTF8.GetBytes($payload)))
}

$emptyClaimFilter = @{
    type = 'and'
    filters = @(
        @{ columnName = 'vorgangKey'; condition = 'eq'; value = $VorgangKey }
        @{ columnName = 'claim_owner'; condition = 'eq'; value = $null }
        @{ columnName = 'claim_expires_at'; condition = 'eq'; value = $null }
    )
}

try {
    if (-not $PSCmdlet.ShouldProcess(
        "allris_vorgaenge/$VorgangKey",
        'Claim setzen, zweiten Claim abweisen und eigenen Claim freigeben'
    )) {
        exit 0
    }

    $now = (Get-Date).ToUniversalTime()
    $first = Invoke-RowUpdate -Filter $emptyClaimFilter -Data @{
        claim_owner = $owner1
        claim_stage = 'dispatcher_test'
        claim_acquired_at = $now.ToString('o')
        claim_expires_at = $now.AddMinutes(30).ToString('o')
    }
    $acquired = $first.Count -eq 1

    if (-not $acquired -or $first[0].claim_owner -ne $owner1) {
        throw 'Erster Claim wurde nicht erworben. Die Zeile fehlt oder ist bereits beansprucht.'
    }

    $second = Invoke-RowUpdate -Filter $emptyClaimFilter -Data @{
        claim_owner = $owner2
        claim_stage = 'dispatcher_test'
        claim_acquired_at = $now.ToString('o')
        claim_expires_at = $now.AddMinutes(30).ToString('o')
    }

    if ($second.Count -ne 0) {
        throw "Doppelclaim nicht blockiert: zweiter Owner änderte $($second.Count) Zeile(n)."
    }

    Write-Host 'PASS: erster Claim erworben; stale Doppelclaim atomar blockiert.' -ForegroundColor Green
}
finally {
    if ($acquired) {
        $release = Invoke-RowUpdate -Filter @{
            type = 'and'
            filters = @(
                @{ columnName = 'vorgangKey'; condition = 'eq'; value = $VorgangKey }
                @{ columnName = 'claim_owner'; condition = 'eq'; value = $owner1 }
            )
        } -Data @{
            claim_owner = $null
            claim_stage = $null
            claim_acquired_at = $null
            claim_expires_at = $null
        }

        if ($release.Count -ne 1) {
            throw "Eigener Test-Claim konnte nicht eindeutig freigegeben werden: $($release.Count) Zeile(n)."
        }
        Write-Host 'PASS: eigener Claim vollständig freigegeben.' -ForegroundColor Green
    }
}

$readFilter = @{
    type = 'and'
    filters = @(
        @{ columnName = 'vorgangKey'; condition = 'eq'; value = $VorgangKey }
    )
} | ConvertTo-Json -Depth 5 -Compress
$encodedFilter = [uri]::EscapeDataString($readFilter)
$readResult = Invoke-RestMethod -Uri "${rowsUri}?limit=2&filter=$encodedFilter" -Headers $headers
$rows = @($readResult.data)

if ($rows.Count -ne 1) {
    throw "Abschluss-Read lieferte $($rows.Count) statt genau einer Zeile."
}

$row = $rows[0]
if ($null -ne $row.claim_owner -or
    $null -ne $row.claim_stage -or
    $null -ne $row.claim_acquired_at -or
    $null -ne $row.claim_expires_at) {
    throw 'Abschluss-Read: mindestens ein Claim-Feld ist nicht leer.'
}

Write-Host 'PASS: Abschluss-Read bestätigt vier leere Claim-Felder.' -ForegroundColor Green
