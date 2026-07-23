# Paket 2 — Data-Table-Spezifikation zum manuellen Anlegen in n8n

Diese Spezifikation gehört zur Architekturprüfung vom 2026-07-22
(`ALLRIS_Architekturpruefung_2026-07-22.md`, Abschnitt 9.2/9.3, Umsetzungsplan
Paket 2). Sie kann **ausschließlich in der n8n-UI oder per n8n-API** angelegt
werden — reine JSON-Datei-Edits reichen dafür nicht aus. Sobald die Tabelle
und die Spalten unten angelegt sind, verdrahte ich die Workflows dagegen
(additive Insert-/Update-Nodes, keine bestehende Logik wird dafür verändert).

---

## 1. Neue Data Table: `allris_state_history`

Anlegen im selben Projekt wie `allris_vorgaenge` (Projekt `CrnegVcMvlcRU0OP`).

**Status 2026-07-23:** angelegt als Data Table `Q54kptpOrbug6bJu`; alle elf
Spalten sind vorhanden.

| Spalte | Typ | Pflicht | Hinweis |
|---|---|---|---|
| `event_id` | string | nein | pro Zeile eine neue UUID/Zeitstempel-ID, wird beim Insert vom Workflow gesetzt |
| `vorgang_key` | string | ja | fachlicher Schlüssel, wie in `allris_vorgaenge.vorgangKey` |
| `pipeline_stage` | string | ja | einer von: `ingestion`, `archive`, `extraction`, `analysis`, `judgment`, `approval`, `content`, `visual`, `image`, `publication`, `paperless` |
| `old_state` | string | nein | Wert vor der Änderung |
| `new_state` | string | ja | Wert nach der Änderung |
| `reason_code` | string | nein | einer der Fehlercodes aus Abschnitt 2 unten, falls zutreffend |
| `reason_message` | string | nein | Freitext |
| `workflow_name` | string | ja | z. B. `ALLRIS_P3_Bewertung` |
| `workflow_execution_id` | string | nein | `{{ $execution.id }}` |
| `created_at` | string (ISO-Datum) | ja | `{{ $now.toISO() }}` |
| `metadata_json` | string | nein | freies JSON-Blob für Zusatzkontext |

Kein Primärschlüssel/Unique-Constraint nötig — die Tabelle ist ein reines
Append-Log, es wird nie aktualisiert oder gelöscht.

**Empfohlener Index (falls die n8n-Data-Table-UI das anbietet):** `vorgang_key`,
damit spätere Auswertungen ("zeig mir die Historie dieses Vorgangs") schnell
bleiben.

---

## 2. Neue Spalten auf der bestehenden Tabelle `allris_vorgaenge`

**Status 2026-07-23:** vollständig angelegt. Der idempotente Wartungsjob
`scripts/Initialize-AllrisStateSchema.ps1` zeigt die fehlenden Spalten zunächst
nur an und ergänzt sie erst mit dem Parameter `-Apply`. Er liest den API-Key
ausschließlich aus `N8N_API_KEY` oder dem nicht empfohlenen Laufzeitparameter
`-ApiKey`; der Schlüssel wird nicht versioniert.

Vorschau:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass `
  -File .\scripts\Initialize-AllrisStateSchema.ps1
```

Ausführung:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass `
  -File .\scripts\Initialize-AllrisStateSchema.ps1 -Apply
```

| Spalte | Typ | Default | Hinweis |
|---|---|---|---|
| `last_error_code` | string | leer | einer der stabilen Codes unten |
| `last_error_message` | string | leer | Freitext |
| `last_error_stage` | string | leer | wie `pipeline_stage` oben |
| `last_error_at` | string (ISO-Datum) | leer | |
| `retry_count` | number | 0 | |
| `next_retry_at` | string (ISO-Datum) | leer | |

### Stabile Fehlercodes (aus der Architekturprüfung, Abschnitt 9.3)

```
SOURCE_TEXT_MISSING
SOURCE_LOCK_FAILED
FACTS_QA_FAILED
CONTENT_JSON_INVALID
VISUAL_ANCHORS_MISSING
IMAGE_QA_FAILED
MATRIX_SEND_FAILED
NEXTCLOUD_UPLOAD_FAILED
PAPERLESS_IMPORT_FAILED
WORDPRESS_PUBLISH_FAILED
```

---

## 3. Rückbau

Falls das Paket zurückgerollt werden muss: die 6 neuen Spalten auf
`allris_vorgaenge` sowie die Tabelle `allris_state_history` können über die
n8n-UI ("Spalte löschen" / "Data Table löschen") wieder entfernt werden.
Bestehende Workflows lesen diese Felder erst, nachdem sie in einem
Folgeschritt verdrahtet wurden — bis dahin ist ihre bloße Existenz folgenlos.

---

## 4. Nächster Schritt

Sobald du mir bestätigst, dass Tabelle + Spalten angelegt sind (inkl. der
`dataTableId`, die n8n beim Anlegen vergibt), ergänze ich in einem eigenen,
isoliert testbaren Schritt additive Insert-/Update-Nodes in den betroffenen
Workflows — ohne bestehende Nodes/Verbindungen zu verändern.
