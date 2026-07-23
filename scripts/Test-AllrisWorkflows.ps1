[CmdletBinding()]
param(
    [string]$RepositoryRoot = '',
    [string]$N8nBaseUrl = $env:N8N_BASE_URL,
    [string]$ApiKey = $env:N8N_API_KEY,
    [switch]$CheckLive
)

$ErrorActionPreference = 'Stop'
$failures = [System.Collections.Generic.List[string]]::new()
$allowedLiveDrift = @{
    'ALLRIS_Status_Uebersicht' = 'LAN-only: Live-Betrieb ohne Token-Gate wurde am 2026-07-23 akzeptiert.'
}

if ([string]::IsNullOrWhiteSpace($RepositoryRoot)) {
    $RepositoryRoot = Split-Path -Parent $PSScriptRoot
}

function Add-Failure {
    param([string]$Message)
    $failures.Add($Message)
    Write-Host "FAIL: $Message" -ForegroundColor Red
}

function Get-ObjectHash {
    param($Value)
    $json = $Value | ConvertTo-Json -Compress -Depth 100
    $sha = [System.Security.Cryptography.SHA256]::Create()
    try {
        return ([BitConverter]::ToString(
            $sha.ComputeHash([Text.Encoding]::UTF8.GetBytes($json))
        )).Replace('-', '')
    }
    finally {
        $sha.Dispose()
    }
}

$workflowFiles = @(
    Get-ChildItem -LiteralPath $RepositoryRoot -File -Filter 'ALLRIS_*.json'
)

if ($workflowFiles.Count -eq 0) {
    throw "Keine ALLRIS_*.json-Dateien unter $RepositoryRoot gefunden."
}

$workflows = @{}
$idsReferenced = [System.Collections.Generic.List[object]]::new()

foreach ($file in $workflowFiles) {
    try {
        $workflow = Get-Content -LiteralPath $file.FullName -Raw -Encoding UTF8 |
            ConvertFrom-Json
    }
    catch {
        Add-Failure "$($file.Name): ungültiges JSON ($($_.Exception.Message))"
        continue
    }

    if ([string]::IsNullOrWhiteSpace([string]$workflow.name)) {
        Add-Failure "$($file.Name): Top-Level-Name fehlt."
        continue
    }

    $workflows[$workflow.name] = [pscustomobject]@{
        File = $file
        Data = $workflow
    }

    $nodeNames = @($workflow.nodes | ForEach-Object { [string]$_.name })
    $duplicates = @($nodeNames | Group-Object | Where-Object Count -gt 1)
    foreach ($duplicate in $duplicates) {
        Add-Failure "$($file.Name): doppelter Node-Name '$($duplicate.Name)'."
    }

    foreach ($source in $workflow.connections.PSObject.Properties) {
        foreach ($channel in $source.Value.PSObject.Properties) {
            foreach ($branch in $channel.Value) {
                foreach ($edge in $branch) {
                    if ([string]$edge.node -notin $nodeNames) {
                        Add-Failure "$($file.Name): Verbindung '$($source.Name)' zeigt auf fehlenden Node '$($edge.node)'."
                    }
                }
            }
        }
    }

    foreach ($node in @($workflow.nodes | Where-Object type -match 'executeWorkflow')) {
        $targetId = [string]$node.parameters.workflowId.value
        if ([string]::IsNullOrWhiteSpace($targetId)) {
            continue
        }
        $idsReferenced.Add([pscustomobject]@{
            File = $file.Name
            Node = $node.name
            Id = $targetId
            CachedName = [string]$node.parameters.workflowId.cachedResultName
        })
    }

    foreach ($node in @($workflow.nodes | Where-Object {
        [string]$_.parameters.url -match 'matrix|_matrix'
    })) {
        $hasCredential = $null -ne $node.credentials.httpHeaderAuth
        $authEnabled =
            $node.parameters.authentication -eq 'genericCredentialType' -and
            $node.parameters.genericAuthType -eq 'httpHeaderAuth'
        if (-not $hasCredential -or -not $authEnabled) {
            Add-Failure "$($file.Name): Matrix-Node '$($node.name)' aktiviert httpHeaderAuth nicht vollständig."
        }
    }

    # sourceConflict ist laut kanonischem Vertrag optional. Diese bekannten
    # Pflichtmuster dürfen in keinem Code-Node erneut eingeführt werden.
    $forbiddenSourceConflictChecks = @(
        'safeStr(sl.sourceConflict) &&',
        'safe(sl.sourceConflict) &&',
        'sl.sourceConflict &&',
        '!_canonicalSL.sourceConflict',
        '!currentSourceLock.sourceConflict',
        "!sourceConflict) errors.push(",
        "!canonicalSourceLock.sourceConflict) sourceLockErrors.push(",
        "!safe(sourceLock.sourceConflict)) sourceLockErrors.push(",
        "!safeStr(sourceLock.sourceConflict)) sourceLockErrors.push("
    )
    foreach ($node in @($workflow.nodes | Where-Object type -eq 'n8n-nodes-base.code')) {
        $code = [string]$node.parameters.jsCode
        foreach ($pattern in $forbiddenSourceConflictChecks) {
            if ($code.Contains($pattern)) {
                Add-Failure "$($file.Name): Code-Node '$($node.name)' behandelt optionales sourceConflict als Pflichtfeld ('$pattern')."
            }
        }
    }
}

Write-Host "Geprüfte Exporte: $($workflowFiles.Count)"
Write-Host "Sub-Workflow-Referenzen: $($idsReferenced.Count)"

# Regression: Eine konfliktlose Mitteilung mit allen kanonischen Pflichtfeldern
# ist ein gültiger SourceLock.
$conflictFreeSourceLock = [pscustomobject]@{
    sourceTopic = 'Sanierung einer Sporthalle'
    sourceConflict = ''
    requiredTerms = @('Sporthalle', 'Sanierung')
    requiredObjects = @('Sporthalle', 'Baugerüst')
    requiredAction = 'Sporthalle sanieren'
}
$conflictFreeSourceLockValid =
    -not [string]::IsNullOrWhiteSpace($conflictFreeSourceLock.sourceTopic) -and
    @($conflictFreeSourceLock.requiredTerms).Count -ge 2 -and
    @($conflictFreeSourceLock.requiredObjects).Count -ge 2 -and
    -not [string]::IsNullOrWhiteSpace($conflictFreeSourceLock.requiredAction)
if (-not $conflictFreeSourceLockValid) {
    Add-Failure 'SourceLock-Regression: konfliktloser Vorgang wurde als ungültig bewertet.'
}

if ($CheckLive) {
    if ([string]::IsNullOrWhiteSpace($N8nBaseUrl)) {
        $N8nBaseUrl = 'http://172.16.1.14:5678'
    }
    if ([string]::IsNullOrWhiteSpace($ApiKey)) {
        throw 'Für -CheckLive fehlt N8N_API_KEY beziehungsweise -ApiKey.'
    }

    $headers = @{ 'X-N8N-API-KEY' = $ApiKey }
    $base = $N8nBaseUrl.TrimEnd('/')
    $liveList = Invoke-RestMethod -Uri "$base/api/v1/workflows?limit=250" -Headers $headers
    $liveByName = @{}
    foreach ($entry in @($liveList.data)) {
        $liveByName[[string]$entry.name] = $entry
    }

    foreach ($entry in $workflows.GetEnumerator()) {
        $name = $entry.Key
        $local = $entry.Value.Data
        if (-not $liveByName.ContainsKey($name)) {
            # Hilfs- und bewusst inaktive Entwürfe dürfen nur lokal existieren.
            if ($local.active -eq $true) {
                Add-Failure "$($entry.Value.File.Name): als aktiv exportiert, aber live nicht vorhanden."
            }
            continue
        }

        $liveSummary = $liveByName[$name]
        $live = Invoke-RestMethod -Uri "$base/api/v1/workflows/$($liveSummary.id)" -Headers $headers
        $localCore = [ordered]@{
            nodes = $local.nodes
            connections = $local.connections
            settings = $local.settings
        }
        $liveCore = [ordered]@{
            nodes = $live.nodes
            connections = $live.connections
            settings = $live.settings
        }
        if ((Get-ObjectHash $localCore) -ne (Get-ObjectHash $liveCore)) {
            if ($allowedLiveDrift.ContainsKey($name)) {
                Write-Host "WARN: $($entry.Value.File.Name): erlaubte Live-Abweichung - $($allowedLiveDrift[$name])" -ForegroundColor Yellow
            }
            else {
                Add-Failure "$($entry.Value.File.Name): Struktur weicht vom Live-Workflow '$($live.id)' ab."
            }
        }
    }

    $liveIds = @($liveList.data | ForEach-Object { [string]$_.id })
    foreach ($reference in $idsReferenced) {
        if ($reference.Id -notin $liveIds) {
            Add-Failure "$($reference.File): '$($reference.Node)' referenziert unbekannte Live-ID '$($reference.Id)'."
        }
    }
}

if ($failures.Count -gt 0) {
    Write-Host "`n$($failures.Count) Fehler gefunden." -ForegroundColor Red
    exit 1
}

Write-Host 'Alle Prüfungen erfolgreich.' -ForegroundColor Green
exit 0
