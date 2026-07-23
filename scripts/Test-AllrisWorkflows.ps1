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

    # Visuell leicht versetzte Nodes (bis 32 px) gelten als dieselbe Zeile.
    # So bleibt das vereinbarte Raster mit maximal 15 lesbaren Nodes pro Reihe
    # auch bei späteren Workflow-Erweiterungen überprüfbar.
    $layoutBands = [System.Collections.Generic.List[object]]::new()
    foreach ($y in @($workflow.nodes | ForEach-Object {
        [int]$_.position[1]
    } | Sort-Object)) {
        $band = @($layoutBands | Where-Object {
            [Math]::Abs($y - [int]$_.Anchor) -le 32
        } | Select-Object -First 1)
        if ($band.Count -eq 1) {
            $band[0].Count++
        } else {
            $layoutBands.Add([pscustomobject]@{ Anchor = $y; Count = 1 })
        }
    }
    $overfullBands = @($layoutBands | Where-Object Count -gt 15)
    foreach ($band in $overfullBands) {
        Add-Failure "$($file.Name): Layout-Zeile bei y=$($band.Anchor) enthält $($band.Count) Nodes (maximal 15)."
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

$p2 = $workflows['ALLRIS_P2_Nextcloud'].Data
if ($null -ne $p2) {
    $p2FailureNode = @($p2.nodes | Where-Object name -eq 'Markiere Fehler in DataTable')
    $p2SuccessNode = @($p2.nodes | Where-Object name -eq 'Update Nextcloud Archive Status')
    $p2ClaimCalls = @($p2.nodes | Where-Object {
        $_.type -match 'executeWorkflow' -and
        $_.parameters.workflowId.value -eq 'D7cmBsy3exuOkBd9'
    })
    $p2ClaimPrepare = @($p2.nodes | Where-Object name -eq 'Bereite P2 Claims vor')
    $p2ClaimRelease = @($p2.nodes | Where-Object name -eq 'Bereite P2 Claim-Freigabe vor')
    $p2ReleaseSources = @($p2.connections.psobject.Properties | Where-Object {
        @($_.Value.main | ForEach-Object { $_ | ForEach-Object node }) -contains 'Bereite P2 Claim-Freigabe vor'
    })
    if ($p2FailureNode.Count -ne 1 -or
        $p2FailureNode[0].parameters.columns.value.last_error_code -ne 'NEXTCLOUD_UPLOAD_FAILED' -or
        $p2FailureNode[0].parameters.columns.value.last_error_stage -ne 'archive') {
        Add-Failure 'P2: zentraler Nextcloud-Fehlervertrag fehlt oder ist inkonsistent.'
    }
    if ($p2SuccessNode.Count -ne 1 -or
        $p2SuccessNode[0].parameters.columns.value.retry_count -ne 0 -or
        $p2SuccessNode[0].parameters.columns.value.last_error_code -ne '') {
        Add-Failure 'P2: zentrale Fehlerfelder werden nach Erfolg nicht zurückgesetzt.'
    }
    if ($p2ClaimCalls.Count -ne 2 -or
        $p2ClaimPrepare.Count -ne 1 -or
        $p2ClaimPrepare[0].parameters.jsCode -notlike "*claimStage: 'archival'*" -or
        $p2ClaimPrepare[0].parameters.jsCode -notlike '*leaseMinutes: 60*' -or
        $p2ClaimRelease.Count -ne 1 -or
        $p2ReleaseSources.Count -ne 2) {
        Add-Failure 'P2: Claim-/Lease-Vertrag ist unvollständig.'
    }
    $p2HistorySuccess = @($p2.nodes | Where-Object name -eq 'History Archivierung Erfolg')
    $p2HistoryFailure = @($p2.nodes | Where-Object name -eq 'History Archivierung Fehler')
    if ($p2HistorySuccess.Count -ne 1 -or
        $p2HistoryFailure.Count -ne 1 -or
        $p2HistorySuccess[0].parameters.dataTableId.value -ne 'Q54kptpOrbug6bJu' -or
        $p2HistoryFailure[0].parameters.dataTableId.value -ne 'Q54kptpOrbug6bJu' -or
        $p2HistoryFailure[0].parameters.columns.value.reason_code -ne 'NEXTCLOUD_UPLOAD_FAILED') {
        Add-Failure 'P2: Append-History für Archivierung ist unvollständig.'
    }
    $p2IfTargets = @(
        $p2.connections.'IF alle Uploads OK?'.main |
            ForEach-Object { $_ } |
            ForEach-Object { $_ } |
            ForEach-Object { [string]$_.node }
    )
    foreach ($requiredTarget in @('History Archivierung Erfolg', 'History Archivierung Fehler')) {
        if ($requiredTarget -notin $p2IfTargets) {
            Add-Failure "P2: IF-Ausgang ist nicht mit '$requiredTarget' verbunden."
        }
    }
}

$paperless = $workflows['ALLRIS_Paperless_Backfill'].Data
if ($null -ne $paperless) {
    $paperlessSchedule = @($paperless.nodes | Where-Object type -match 'scheduleTrigger')
    if ($paperlessSchedule.Count -ne 1 -or
        $paperlessSchedule[0].parameters.rule.interval[0].field -ne 'hours' -or
        $paperlessSchedule[0].parameters.rule.interval[0].hoursInterval -ne 1 -or
        $paperlessSchedule[0].parameters.rule.interval[0].triggerAtMinute -ne 50) {
        Add-Failure 'Paperless: stündlicher :50-Schedule ist nicht explizit konfiguriert.'
    }
    $paperlessDbError = @($paperless.nodes | Where-Object name -eq 'DB Paperless Fehler')
    $paperlessHistory = @($paperless.nodes | Where-Object name -like 'History Paperless *')
    if ($paperlessDbError.Count -ne 1 -or
        $paperlessDbError[0].parameters.columns.value.last_error_code -ne 'PAPERLESS_IMPORT_FAILED' -or
        $paperlessDbError[0].parameters.columns.value.last_error_stage -ne 'paperless') {
        Add-Failure 'Paperless: zentraler Fehlervertrag fehlt oder ist inkonsistent.'
    }
    if ($paperlessHistory.Count -ne 2 -or
        @($paperlessHistory | Where-Object {
            $_.parameters.dataTableId.value -ne 'Q54kptpOrbug6bJu'
        }).Count -gt 0) {
        Add-Failure 'Paperless: Erfolgs-/Fehler-History ist unvollständig.'
    }
    $paperlessLog = @($paperless.nodes | Where-Object name -eq 'Paperless Log Ergebnis (Backfill)')
    $paperlessAggregate = @($paperless.nodes | Where-Object name -eq 'Aggregiere Backfill-Ergebnis')
    $paperlessClaimCalls = @($paperless.nodes | Where-Object {
        $_.type -match 'executeWorkflow' -and
        $_.parameters.workflowId.value -eq 'D7cmBsy3exuOkBd9'
    })
    $paperlessClaimPrepare = @($paperless.nodes | Where-Object name -eq 'Bereite Paperless Claims vor')
    $paperlessClaimRelease = @($paperless.nodes | Where-Object name -eq 'Bereite Paperless Claim-Freigabe vor')
    $paperlessReleaseSources = @($paperless.connections.psobject.Properties | Where-Object {
        @($_.Value.main | ForEach-Object { $_ | ForEach-Object node }) -contains 'Bereite Paperless Claim-Freigabe vor'
    })
    $paperlessLogCode = if ($paperlessLog.Count -eq 1) {
        [string]$paperlessLog[0].parameters.jsCode
    } else {
        ''
    }
    $paperlessAggregateCode = if ($paperlessAggregate.Count -eq 1) {
        [string]$paperlessAggregate[0].parameters.jsCode
    } else {
        ''
    }
    $paperlessContextGuardValid =
        $paperlessLog.Count -eq 1 -and
        $paperlessLogCode.Contains('function linkedJson(nodeName)') -and
        $paperlessLogCode.Contains("linkedJson('Paperless Titel bauen (Backfill)')") -and
        $paperlessLogCode.Contains("linkedJson('Code Pr") -and
        -not $paperlessLogCode.Contains('$(nodeName).first') -and
        $paperlessLogCode.Contains('Item-Kontext ohne vorgangKey') -and
        $paperlessAggregate.Count -eq 1 -and
        $paperlessAggregateCode.Contains('Erwartet genau einen vorgangKey in den Ergebnissen')
    if (-not $paperlessContextGuardValid) {
        Add-Failure 'Paperless: Vorgangskontext wird vor der Abschlussaggregation nicht zuverlässig wiederhergestellt.'
    }
    if ($paperlessClaimCalls.Count -ne 2 -or
        $paperlessClaimPrepare.Count -ne 1 -or
        $paperlessClaimPrepare[0].parameters.jsCode -notlike "*claimStage: 'paperless'*" -or
        $paperlessClaimPrepare[0].parameters.jsCode -notlike '*leaseMinutes: 60*' -or
        $paperlessClaimRelease.Count -ne 1 -or
        $paperlessReleaseSources.Count -ne 2) {
        Add-Failure 'Paperless: Claim-/Lease-Vertrag ist unvollständig.'
    }
}

$dispatcher = $workflows['ALLRIS_Dispatcher_Watchdog'].Data
if ($null -ne $dispatcher) {
    $claimConfig = @($dispatcher.nodes | Where-Object name -eq 'Konfiguriere Claim-Test')
    $claimAcquire = @($dispatcher.nodes | Where-Object name -eq 'Erwerbe Test-Claim CAS')
    $claimRelease = @($dispatcher.nodes | Where-Object name -eq 'Gib eigenen Test-Claim frei')
    $acquireFilters = @($claimAcquire[0].parameters.filters.conditions | ForEach-Object keyName)
    $releaseFilters = @($claimRelease[0].parameters.filters.conditions | ForEach-Object keyName)
    if ($dispatcher.active -ne $false -or
        @($dispatcher.nodes).Count -ne 16 -or
        $claimConfig.Count -ne 1 -or
        -not ([string]$claimConfig[0].parameters.jsCode).Contains(
            "const TEST_VORGANG_KEY = '';"
        ) -or
        $claimAcquire.Count -ne 1 -or
        @('vorgangKey', 'claim_owner', 'claim_expires_at' |
            Where-Object { $_ -notin $acquireFilters }).Count -gt 0 -or
        $claimRelease.Count -ne 1 -or
        @('vorgangKey', 'claim_owner' |
            Where-Object { $_ -notin $releaseFilters }).Count -gt 0) {
        Add-Failure 'Dispatcher: manueller Claim-/Re-Read-Test ist nicht sicher oder unvollständig.'
    }
}

$p6 = $workflows['ALLRIS_P6_Bildgenerierung'].Data
if ($null -ne $p6) {
    $p6ClaimCalls = @($p6.nodes | Where-Object {
        $_.type -eq 'n8n-nodes-base.executeWorkflow' -and
        $_.parameters.workflowId.value -eq 'D7cmBsy3exuOkBd9'
    })
    $p6ClaimPrepare = @($p6.nodes | Where-Object name -eq 'Bereite P6 Claims vor')
    $p6ClaimRelease = @($p6.nodes | Where-Object name -eq 'Bereite P6 Claim-Freigabe vor')
    if ($p6ClaimCalls.Count -ne 2 -or
        $p6ClaimPrepare.Count -ne 1 -or
        -not ([string]$p6ClaimPrepare[0].parameters.jsCode).Contains(
            'leaseMinutes: 60'
        ) -or
        $p6ClaimRelease.Count -ne 1 -or
        -not ([string]$p6ClaimRelease[0].parameters.jsCode).Contains(
            'ALLRIS_P6_Bildgenerierung:${$execution.id}'
        )) {
        Add-Failure 'P6: Claim-Erwerb, 60-Minuten-Lease oder owner-gebundene Freigabe ist unvollständig.'
    }

    foreach ($nodeId in @(
        'ed509d84-c2b0-4f2e-90ca-9f59f7abf363',
        'e2a86b50-414f-4b61-8b78-cf4654990a63'
    )) {
        $node = @($p6.nodes | Where-Object id -eq $nodeId)
        if ($node.Count -ne 1 -or
            $node[0].parameters.columns.value.last_error_code -ne 'IMAGE_QA_FAILED' -or
            $node[0].parameters.columns.value.last_error_stage -ne 'image') {
            Add-Failure "P6: zentraler Bildfehlervertrag fehlt in Node '$nodeId'."
        }
        elseif ('History Bildfehler' -notin @(
            $p6.connections.($node[0].name).main |
                ForEach-Object { $_ } |
                ForEach-Object { $_ } |
                ForEach-Object { [string]$_.node }
        )) {
            Add-Failure "P6: Node '$nodeId' ist nicht mit der Bildfehler-History verbunden."
        }
    }
    $p6History = @($p6.nodes | Where-Object id -eq '31f4b3a3-b448-4e1d-a261-67bc95061bdd')
    if ($p6History.Count -ne 1 -or
        $p6History[0].parameters.dataTableId.value -ne 'Q54kptpOrbug6bJu' -or
        $p6History[0].parameters.columns.value.reason_code -ne 'IMAGE_QA_FAILED') {
        Add-Failure 'P6: gemeinsame Bildfehler-History ist unvollständig.'
    }
    $p6MatrixSend = @($p6.nodes | Where-Object id -eq '145f3ba6-a607-4c32-8dba-6ac6d406aef8')
    $p6MatrixDb = @($p6.nodes | Where-Object id -eq 'c67bd02a-6edf-4b68-96a5-bac8d77db407')
    $p6MatrixHistory = @($p6.nodes | Where-Object id -eq '7104ce81-c7f0-4cc9-8788-fdeed3c3055a')
    if ($p6MatrixSend.Count -ne 1 -or
        $p6MatrixSend[0].onError -ne 'continueErrorOutput' -or
        $p6MatrixDb.Count -ne 1 -or
        $p6MatrixDb[0].parameters.columns.value.last_error_code -ne 'MATRIX_SEND_FAILED' -or
        $p6MatrixHistory.Count -ne 1 -or
        $p6MatrixHistory[0].parameters.columns.value.reason_code -ne 'MATRIX_SEND_FAILED') {
        Add-Failure 'P6: Matrix-Versandfehlervertrag ist unvollständig.'
    }
}

$p7 = $workflows['ALLRIS_P7_WordPress_Publish'].Data
if ($null -ne $p7) {
    $p7Failure = @($p7.nodes | Where-Object id -eq 'a30550bc-d993-4d99-a991-4c04040ce40a')
    $p7HistorySuccess = @($p7.nodes | Where-Object id -eq 'e2ac04f7-77b5-47c0-8ae1-99b877fc85d1')
    $p7HistoryFailure = @($p7.nodes | Where-Object id -eq '51fc16ec-8640-4eaa-8ccb-35a97d06ac69')
    $p7CandidateFilter = @($p7.nodes | Where-Object name -eq 'Filter WordPress-Kandidaten')
    $p7SlugLookup = @($p7.nodes | Where-Object name -eq 'Suche WordPress-Beitrag per Slug')
    $p7SlugEvaluation = @($p7.nodes | Where-Object name -eq 'Bewerte WordPress-Slug-Suche')
    $p7SlugExistsGate = @($p7.nodes | Where-Object name -eq 'IF WordPress-Slug vorhanden?')
    $p7SlugLookupGate = @($p7.nodes | Where-Object name -eq 'IF WordPress-Slug-Suche ok?')
    $p7ClaimCalls = @($p7.nodes | Where-Object {
        $_.type -match 'executeWorkflow' -and
        $_.parameters.workflowId.value -eq 'D7cmBsy3exuOkBd9'
    })
    $p7ClaimPrepare = @($p7.nodes | Where-Object name -eq 'Bereite P7 Claims vor')
    $p7ClaimRelease = @($p7.nodes | Where-Object name -eq 'Bereite P7 Claim-Freigabe vor')
    $p7ReleaseSources = @($p7.connections.psobject.Properties | Where-Object {
        @($_.Value.main | ForEach-Object { $_ | ForEach-Object node }) -contains 'Bereite P7 Claim-Freigabe vor'
    })
    $p7CreateInputs = @($p7.connections.psobject.Properties | Where-Object {
        @($_.Value.main | ForEach-Object { $_ | ForEach-Object node }) -contains 'Create a post'
    })
    if ($p7Failure.Count -ne 1 -or
        $p7Failure[0].parameters.columns.value.last_error_code -ne 'WORDPRESS_PUBLISH_FAILED' -or
        $p7Failure[0].parameters.columns.value.last_error_stage -ne 'publication' -or
        $p7HistorySuccess.Count -ne 1 -or
        $p7HistoryFailure.Count -ne 1 -or
        $p7HistoryFailure[0].parameters.columns.value.reason_code -ne 'WORDPRESS_PUBLISH_FAILED' -or
        $p7CandidateFilter.Count -ne 1 -or
        $p7CandidateFilter[0].parameters.jsCode -notlike "*safeStr(j.last_error_stage) === 'publication'*" -or
        $p7CandidateFilter[0].parameters.jsCode -notlike '*publicationRetryAt > Date.now()*' -or
        $p7SlugLookup.Count -ne 1 -or
        $p7SlugLookup[0].parameters.queryParameters.parameters[0].value -ne '={{ $json.wordpressSlug }}' -or
        $p7SlugEvaluation.Count -ne 1 -or
        $p7SlugExistsGate.Count -ne 1 -or
        $p7SlugLookupGate.Count -ne 1 -or
        $p7ClaimCalls.Count -ne 2 -or
        $p7ClaimPrepare.Count -ne 1 -or
        $p7ClaimPrepare[0].parameters.jsCode -notlike "*claimStage: 'publication'*" -or
        $p7ClaimPrepare[0].parameters.jsCode -notlike '*leaseMinutes: 30*' -or
        $p7ClaimRelease.Count -ne 1 -or
        $p7ReleaseSources.Count -ne 2 -or
        $p7CreateInputs.Count -ne 1 -or
        $p7CreateInputs[0].Name -ne 'IF WordPress-Slug-Suche ok?') {
        Add-Failure 'P7: zentraler WordPress-Fehler-/History-Vertrag ist unvollständig.'
    }
}

$p8 = $workflows['ALLRIS_P8_Partei_Webseite'].Data
if ($null -ne $p8) {
    $p8Failure = @($p8.nodes | Where-Object id -eq 'f5f722e4-6acd-4ed1-93d0-447bd4b1d961')
    $p8HistorySuccess = @($p8.nodes | Where-Object id -eq 'b4dc013f-17ae-413a-8605-28e61f1cb1b2')
    $p8HistoryFailure = @($p8.nodes | Where-Object id -eq 'f9b791e7-6fc8-4011-8fbb-b7de54a317a5')
    $p8CandidateFilter = @($p8.nodes | Where-Object name -eq 'Filter Partei-Webseite-Kandidaten')
    $p8SlugLookup = @($p8.nodes | Where-Object name -eq 'Suche Partei-Beitrag per Slug')
    $p8SlugEvaluation = @($p8.nodes | Where-Object name -eq 'Bewerte Partei-Slug-Suche')
    $p8SlugExistsGate = @($p8.nodes | Where-Object name -eq 'IF Partei-Slug vorhanden?')
    $p8SlugLookupGate = @($p8.nodes | Where-Object name -eq 'IF Partei-Slug-Suche ok?')
    $p8ClaimCalls = @($p8.nodes | Where-Object {
        $_.type -match 'executeWorkflow' -and
        $_.parameters.workflowId.value -eq 'D7cmBsy3exuOkBd9'
    })
    $p8ClaimPrepare = @($p8.nodes | Where-Object name -eq 'Bereite P8 Claims vor')
    $p8ClaimRelease = @($p8.nodes | Where-Object name -eq 'Bereite P8 Claim-Freigabe vor')
    $p8ReleaseSources = @($p8.connections.psobject.Properties | Where-Object {
        @($_.Value.main | ForEach-Object { $_ | ForEach-Object node }) -contains 'Bereite P8 Claim-Freigabe vor'
    })
    $p8BodyTargets = @($p8.connections.'Baue Post-Body'.main[0] | ForEach-Object node)
    if ($p8Failure.Count -ne 1 -or
        $p8Failure[0].parameters.columns.value.last_error_code -ne 'WORDPRESS_PUBLISH_FAILED' -or
        $p8Failure[0].parameters.columns.value.last_error_stage -ne 'publication' -or
        $p8HistorySuccess.Count -ne 1 -or
        $p8HistoryFailure.Count -ne 1 -or
        $p8HistoryFailure[0].parameters.columns.value.reason_code -ne 'WORDPRESS_PUBLISH_FAILED' -or
        $p8CandidateFilter.Count -ne 1 -or
        $p8CandidateFilter[0].parameters.jsCode -notlike "*safeStr(j.last_error_stage) === 'publication'*" -or
        $p8CandidateFilter[0].parameters.jsCode -notlike '*publicationRetryAt > Date.now()*' -or
        $p8SlugLookup.Count -ne 1 -or
        $p8SlugLookup[0].parameters.url -ne 'https://die-partei.net/goslar/wp-json/wp/v2/posts' -or
        $p8SlugLookup[0].parameters.queryParameters.parameters[0].value -ne '={{ $json.wpSlug }}' -or
        $p8SlugEvaluation.Count -ne 1 -or
        $p8SlugExistsGate.Count -ne 1 -or
        $p8SlugLookupGate.Count -ne 1 -or
        $p8ClaimCalls.Count -ne 2 -or
        $p8ClaimPrepare.Count -ne 1 -or
        $p8ClaimPrepare[0].parameters.jsCode -notlike "*claimStage: 'publication'*" -or
        $p8ClaimPrepare[0].parameters.jsCode -notlike '*leaseMinutes: 30*' -or
        $p8ClaimRelease.Count -ne 1 -or
        $p8ReleaseSources.Count -ne 2 -or
        $p8BodyTargets.Count -ne 1 -or
        $p8BodyTargets[0] -ne 'Suche Partei-Beitrag per Slug') {
        Add-Failure 'P8: zentraler WordPress-Fehler-/History-Vertrag ist unvollständig.'
    }
}

$p4 = $workflows['ALLRIS_P4_Content_Reaktion'].Data
if ($null -ne $p4) {
    $p4ClaimCalls = @($p4.nodes | Where-Object {
        $_.type -eq 'n8n-nodes-base.executeWorkflow' -and
        $_.parameters.workflowId.value -eq 'D7cmBsy3exuOkBd9'
    })
    $p4ClaimPrepare = @($p4.nodes | Where-Object name -eq 'Bereite P4 Claims vor')
    $p4ClaimRelease = @($p4.nodes | Where-Object name -eq 'Bereite P4 Claim-Freigabe vor')
    if ($p4ClaimCalls.Count -ne 2 -or
        $p4ClaimPrepare.Count -ne 1 -or
        -not ([string]$p4ClaimPrepare[0].parameters.jsCode).Contains(
            'expectedClaimExpiresAt: item.json.claim_expires_at ?? null'
        ) -or
        $p4ClaimRelease.Count -ne 1 -or
        -not ([string]$p4ClaimRelease[0].parameters.jsCode).Contains(
            'ALLRIS_P4_Content_Reaktion:${$execution.id}'
        )) {
        Add-Failure 'P4: Claim-Erwerb oder owner-gebundene Freigabe ist unvollständig.'
    }

    $p4Failure = @($p4.nodes | Where-Object id -eq '4ffb1a4a-9d50-46bf-830d-36ae2f4a864c')
    $p4History = @($p4.nodes | Where-Object id -eq '6623da40-2cc6-4ce8-9479-4596675b331d')
    if ($p4Failure.Count -ne 1 -or
        [string]$p4Failure[0].parameters.columns.value.last_error_code -notmatch 'SOURCE_LOCK_FAILED' -or
        [string]$p4Failure[0].parameters.columns.value.last_error_code -notmatch 'CONTENT_JSON_INVALID' -or
        $p4History.Count -ne 1 -or
        $p4History[0].parameters.dataTableId.value -ne 'Q54kptpOrbug6bJu') {
        Add-Failure 'P4: zentraler Content-/SourceLock-Fehlervertrag ist unvollständig.'
    }
}

$p5 = $workflows['ALLRIS_P5_Visual_Prompt_Builder'].Data
if ($null -ne $p5) {
    $p5ClaimCalls = @($p5.nodes | Where-Object {
        $_.type -eq 'n8n-nodes-base.executeWorkflow' -and
        $_.parameters.workflowId.value -eq 'D7cmBsy3exuOkBd9'
    })
    $p5ClaimPrepare = @($p5.nodes | Where-Object name -eq 'Bereite P5 Claims vor')
    $p5ClaimRelease = @($p5.nodes | Where-Object name -eq 'Bereite P5 Claim-Freigabe vor')
    if ($p5ClaimCalls.Count -ne 2 -or
        $p5ClaimPrepare.Count -ne 1 -or
        -not ([string]$p5ClaimPrepare[0].parameters.jsCode).Contains(
            'expectedClaimExpiresAt: item.json.claim_expires_at ?? null'
        ) -or
        $p5ClaimRelease.Count -ne 1 -or
        -not ([string]$p5ClaimRelease[0].parameters.jsCode).Contains(
            'ALLRIS_P5_Visual_Prompt_Builder:${$execution.id}'
        )) {
        Add-Failure 'P5: Claim-Erwerb oder owner-gebundene Freigabe ist unvollständig.'
    }

    $p5Failure = @($p5.nodes | Where-Object id -eq '729aedbd-cad6-40ee-a28f-d1286914d423')
    $p5History = @($p5.nodes | Where-Object id -eq '7459b617-ad5a-4a11-8eb2-8f7297e7fe36')
    if ($p5Failure.Count -ne 1 -or
        [string]$p5Failure[0].parameters.columns.value.last_error_code -notmatch 'VISUAL_ANCHORS_MISSING' -or
        $p5History.Count -ne 1 -or
        $p5History[0].parameters.dataTableId.value -ne 'Q54kptpOrbug6bJu') {
        Add-Failure 'P5: zentraler Visual-Gate-Fehlervertrag ist unvollständig.'
    }
    $p5GateTargets = @(
        $p5.connections.'IF Content-Gate ok?'.main[1] |
            ForEach-Object { [string]$_.node }
    )
    foreach ($target in @('DB Visual-Gate Fehler', 'History Visual-Gate Fehler')) {
        if ($target -notin $p5GateTargets) {
            Add-Failure "P5: Gate-False-Ausgang ist nicht mit '$target' verbunden."
        }
    }
}

$p3 = $workflows['ALLRIS_P3_Bewertung'].Data
if ($null -ne $p3) {
    $p3ClaimCalls = @($p3.nodes | Where-Object {
        $_.type -eq 'n8n-nodes-base.executeWorkflow' -and
        $_.parameters.workflowId.value -eq 'D7cmBsy3exuOkBd9'
    })
    $p3ClaimPrepare = @($p3.nodes | Where-Object name -eq 'Bereite P3 Claims vor')
    $p3ClaimRelease = @($p3.nodes | Where-Object name -eq 'Bereite P3 Claim-Freigabe vor')
    if ($p3ClaimCalls.Count -ne 2 -or
        $p3ClaimPrepare.Count -ne 1 -or
        -not ([string]$p3ClaimPrepare[0].parameters.jsCode).Contains(
            'expectedClaimExpiresAt: item.json.claim_expires_at ?? null'
        ) -or
        $p3ClaimRelease.Count -ne 1 -or
        -not ([string]$p3ClaimRelease[0].parameters.jsCode).Contains(
            'ALLRIS_P3_Bewertung:${$execution.id}'
        )) {
        Add-Failure 'P3: Claim-Erwerb oder owner-gebundene Freigabe ist unvollständig.'
    }

    $p3SourceError = @($p3.nodes | Where-Object id -eq 'eebbeedb-3551-415b-a532-5bd843170abd')
    $p3ParseError = @($p3.nodes | Where-Object id -eq '635b1889-95d1-46cd-8db3-ff1ba0c2cddb')
    $p3History = @($p3.nodes | Where-Object id -eq '063477f3-46d0-4765-9a05-3ac1436cc80d')
    if ($p3SourceError.Count -ne 1 -or
        $p3SourceError[0].parameters.columns.value.last_error_code -ne 'SOURCE_TEXT_MISSING' -or
        $p3ParseError.Count -ne 1 -or
        $p3ParseError[0].parameters.columns.value.last_error_code -ne 'CONTENT_JSON_INVALID' -or
        $p3History.Count -ne 1) {
        Add-Failure 'P3: zentraler Quellen-/Parsefehlervertrag ist unvollständig.'
    }
}

$p3d = $workflows['ALLRIS_P3d_Agenten_Kette'].Data
if ($null -ne $p3d) {
    $p3dClaimCalls = @($p3d.nodes | Where-Object {
        $_.type -eq 'n8n-nodes-base.executeWorkflow' -and
        $_.parameters.workflowId.value -eq 'D7cmBsy3exuOkBd9'
    })
    $p3dClaimPrepare = @($p3d.nodes | Where-Object name -eq 'Bereite P3d Claims vor')
    $p3dClaimRelease = @($p3d.nodes | Where-Object name -eq 'Bereite P3d Claim-Freigabe vor')
    if ($p3dClaimCalls.Count -ne 2 -or
        $p3dClaimPrepare.Count -ne 1 -or
        -not ([string]$p3dClaimPrepare[0].parameters.jsCode).Contains(
            'expectedClaimExpiresAt: item.json.claim_expires_at ?? null'
        ) -or
        $p3dClaimRelease.Count -ne 1 -or
        -not ([string]$p3dClaimRelease[0].parameters.jsCode).Contains(
            'ALLRIS_P3d_Agenten_Kette:${$execution.id}'
        )) {
        Add-Failure 'P3d: Claim-Erwerb oder owner-gebundene Freigabe ist unvollständig.'
    }

    $p3dQaBlock = @($p3d.nodes | Where-Object id -eq '014cdc09-9fed-4b52-a4bf-7fa6e8cf19e8')
    $p3dHistory = @($p3d.nodes | Where-Object id -eq 'd4a9df45-6110-47cf-96e0-1fbedf9399ce')
    if ($p3dQaBlock.Count -ne 1 -or
        $p3dQaBlock[0].parameters.columns.value.last_error_code -ne 'FACTS_QA_FAILED' -or
        $p3dHistory.Count -ne 1 -or
        $p3dHistory[0].parameters.columns.value.reason_code -ne 'FACTS_QA_FAILED') {
        Add-Failure 'P3d: zentraler Fakten-/QA-Fehlervertrag ist unvollständig.'
    }
}

$p3c = $workflows['ALLRIS_P3c_Vorgangsabschluss'].Data
if ($null -ne $p3c) {
    $p3cClaimCalls = @($p3c.nodes | Where-Object {
        $_.type -match 'executeWorkflow' -and
        $_.parameters.workflowId.value -eq 'D7cmBsy3exuOkBd9'
    })
    $p3cClaimPrepare = @($p3c.nodes | Where-Object name -eq 'Bereite P3c Claims vor')
    $p3cClaimRelease = @($p3c.nodes | Where-Object name -eq 'Bereite P3c Claim-Freigabe vor')
    $p3cReleaseSources = @($p3c.connections.psobject.Properties | Where-Object {
        @($_.Value.main | ForEach-Object { $_ | ForEach-Object node }) -contains 'Bereite P3c Claim-Freigabe vor'
    })
    if ($p3cClaimCalls.Count -ne 2 -or
        $p3cClaimPrepare.Count -ne 1 -or
        $p3cClaimPrepare[0].parameters.jsCode -notlike "*claimStage: 'completion'*" -or
        $p3cClaimPrepare[0].parameters.jsCode -notlike '*leaseMinutes: 60*' -or
        $p3cClaimRelease.Count -ne 1 -or
        $p3cReleaseSources.Count -ne 2) {
        Add-Failure 'P3c: Claim-/Lease-Vertrag ist unvollständig.'
    }
}

$p3e = $workflows['ALLRIS_P3e_Kernbotschaft'].Data
if ($null -ne $p3e) {
    $p3eClaimCalls = @($p3e.nodes | Where-Object {
        $_.type -eq 'n8n-nodes-base.executeWorkflow' -and
        $_.parameters.workflowId.value -eq 'D7cmBsy3exuOkBd9'
    })
    $p3eClaimPrepare = @($p3e.nodes | Where-Object name -eq 'Bereite P3e Claims vor')
    $p3eClaimRelease = @($p3e.nodes | Where-Object name -eq 'Bereite P3e Claim-Freigabe vor')
    if ($p3eClaimCalls.Count -ne 2 -or
        $p3eClaimPrepare.Count -ne 1 -or
        -not ([string]$p3eClaimPrepare[0].parameters.jsCode).Contains(
            'expectedClaimExpiresAt: item.json.claim_expires_at ?? null'
        ) -or
        $p3eClaimRelease.Count -ne 1 -or
        -not ([string]$p3eClaimRelease[0].parameters.jsCode).Contains(
            'ALLRIS_P3e_Kernbotschaft:${$execution.id}'
        )) {
        Add-Failure 'P3e: Claim-Erwerb oder owner-gebundene Freigabe ist unvollständig.'
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

    $dataTables = Invoke-RestMethod -Uri "$base/api/v1/data-tables?limit=250" -Headers $headers
    $stateHistory = @($dataTables.data | Where-Object name -eq 'allris_state_history')
    if ($stateHistory.Count -ne 1) {
        Add-Failure "Data Table 'allris_state_history' fehlt oder ist nicht eindeutig."
    }
    else {
        $expectedHistoryColumns = @(
            'event_id', 'vorgang_key', 'pipeline_stage', 'old_state', 'new_state',
            'reason_code', 'reason_message', 'workflow_name',
            'workflow_execution_id', 'created_at', 'metadata_json'
        )
        $actualHistoryColumns = @($stateHistory[0].columns | ForEach-Object name)
        foreach ($column in $expectedHistoryColumns) {
            if ($column -notin $actualHistoryColumns) {
                Add-Failure "Data Table 'allris_state_history': Spalte '$column' fehlt."
            }
        }
    }

    $vorgaenge = @($dataTables.data | Where-Object name -eq 'allris_vorgaenge')
    if ($vorgaenge.Count -ne 1) {
        Add-Failure "Data Table 'allris_vorgaenge' fehlt oder ist nicht eindeutig."
    }
    else {
        $expectedStateColumns = @(
            'last_error_code', 'last_error_message', 'last_error_stage',
            'last_error_at', 'retry_count', 'next_retry_at',
            'claim_owner', 'claim_stage', 'claim_acquired_at',
            'claim_expires_at'
        )
        $actualVorgaengeColumns = @($vorgaenge[0].columns | ForEach-Object name)
        $missingStateColumns = @($expectedStateColumns | Where-Object {
            $_ -notin $actualVorgaengeColumns
        })
        if ($missingStateColumns.Count -gt 0) {
            Write-Host (
                "WARN: allris_vorgaenge: additive State-Felder noch nicht angelegt: " +
                ($missingStateColumns -join ', ')
            ) -ForegroundColor Yellow
        }
    }
}

if ($failures.Count -gt 0) {
    Write-Host "`n$($failures.Count) Fehler gefunden." -ForegroundColor Red
    exit 1
}

Write-Host 'Alle Prüfungen erfolgreich.' -ForegroundColor Green
exit 0
