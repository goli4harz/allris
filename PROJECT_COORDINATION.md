# ALLRIS – Projektkoordination

Diese Datei ist die gemeinsame Kommunikations- und Übergabestelle für Oliver,
Claude und Codex. Sie ist die maßgebliche Übersicht für Anforderungen, offene
Arbeiten, Entscheidungen und Blocker. Änderungen am Projekt gelten erst dann als
vollständig dokumentiert, wenn diese Datei im selben Commit aktualisiert wurde.

## Arbeitsregeln

1. Vor jeder Änderung diese Datei und das `README.md` lesen.
2. Vor Arbeitsbeginn eine Aufgabe unter **Offene Aufgaben** eintragen oder
   übernehmen.
3. Nie stillschweigend bestehende n8n-IDs, Credentials, Data-Table-Spalten,
   Statuswerte oder Zeitpläne ändern.
4. Workflow-Änderungen mindestens durch JSON-Parsing und eine Prüfung der
   betroffenen Nodes und Verbindungen validieren. Live-Tests ausdrücklich als
   solche dokumentieren.
5. Keine Zugangsdaten, Tokens oder personenbezogenen Quelldaten committen.
6. Nach Abschluss Anforderungen, Entscheidungen, Tests und Übergabe aktualisieren.
7. Jede Übergabe nennt Autor, Datum, betroffene Dateien und den nächsten Schritt.

## Projektziel

ALLRIS-Vorgänge zuverlässig erfassen, archivieren und faktengebunden bewerten,
daraus redaktionell kontrollierbare Inhalte und Sharepics erzeugen und diese über
die vorgesehenen Kanäle veröffentlichen. Automatisierung darf Quellenbindung,
Nachvollziehbarkeit und menschliche Freigaben nicht umgehen.

## Verbindliche Anforderungen

| ID | Anforderung | Status | Hinweise |
|---|---|---|---|
| REQ-001 | Alle Änderungen werden gemeinsam mit ihrer Dokumentation auf GitHub versioniert. | aktiv | README und diese Datei bei relevanten Änderungen mitpflegen |
| REQ-002 | Claude und Codex verwenden diese Datei als gemeinsame Übergabestelle. | aktiv | Keine getrennten, widersprüchlichen Aufgabenlisten führen |
| REQ-003 | Generierte Aussagen und Bilder müssen an belegbare ALLRIS-Quellen gebunden bleiben. | aktiv | SourceLock, Fakten-Agent und QA-Sperren nicht umgehen |
| REQ-004 | Veröffentlichungen bleiben ein isolierter, nachvollziehbarer und kontrollierbarer Schritt. | aktiv | P7/P8 und menschliche Freigaben besonders vorsichtig ändern |
| REQ-005 | Workflow-Ausführungen müssen idempotent und Fehler wiederholbar behandelbar sein. | teilweise | Retry- und Fehlerhistorie noch vervollständigen |
| REQ-006 | Secrets werden ausschließlich über n8n-Credentials oder Umgebungsvariablen bereitgestellt. | aktiv | Keine Secrets in Workflow-Exporte schreiben |

Statuswerte: `geplant`, `aktiv`, `teilweise`, `erfüllt`, `verworfen`.

## Offene Aufgaben

| ID | Priorität | Aufgabe | Zuständig | Status | Abhängigkeit / nächster Schritt |
|---|---|---|---|---|---|
| TASK-001 | hoch | Zentrale State-History und einheitliche Fehlerfelder gemäß `PAKET2_DB_SPEZIFIKATION.md` umsetzen | Codex | in Arbeit | History-Tabelle angelegt; sechs Fehlerfelder auf `allris_vorgaenge` noch per UI ergänzen |
| TASK-002 | hoch | Dispatcher/Watchdog als zuverlässige Pipeline-Steuerung bewerten und fertigstellen | offen | offen | Zustandsübergänge, Retry-Regeln und Parallelität festlegen |
| TASK-003 | hoch | Automatische Strukturtests für alle n8n-JSON-Exporte ergänzen | Codex | erledigt | `scripts/Test-AllrisWorkflows.ps1`, lokal und gegen Live-n8n erfolgreich |
| TASK-004 | mittel | README an tatsächlich vorhandene Stufen und Hilfsworkflows angleichen | Codex | erledigt | P3e, P8, Paperless, Status und Dispatcher/Watchdog dokumentiert |
| TASK-005 | mittel | Lizenz und Beitragsregeln festlegen | Oliver | Entscheidung nötig | gewünschte Lizenz bestimmen |
| TASK-006 | kritisch | Matrix-Authentifizierung im P6-Node `Sende Presseartikel Matrix` aktivieren und testen | Codex | Review | Authentifizierung live aktiviert; kontrollierter Matrix-Funktionstest steht noch aus |
| TASK-007 | kritisch | Fachliche Rolle und positives Veröffentlichungs-Gate für P7 festlegen | Oliver | Entscheidung nötig | Vollarchiv oder redaktioneller Kanal; Audit F-02 |
| TASK-008 | hoch | Kanonischen SourceLock-Vertrag festlegen und `sourceConflict` in allen Stufen einheitlich behandeln | Codex | erledigt | Vertrag dokumentiert; P3b/P4/P5/P6 gemeinsam live veröffentlicht und getestet |
| TASK-009 | hoch | Zeitkaskade durch Claim-/Lease-fähigen Dispatcher absichern | offen | offen | baut auf TASK-001/TASK-002 auf; Audit F-04 |
| TASK-010 | mittel | Workflow-ID- und Infrastruktur-Konfigurationslandkarte anlegen | Codex | erledigt | `docs/WORKFLOW_ID_MAP.md`; Live-IDs werden automatisiert geprüft |
| TASK-011 | kritisch | Wiederkehrende P1-Verbindungsabbrüche zur ALLRIS-Übersicht diagnostizieren und beheben | Codex | blockiert | Ziel liefert `504 Gateway Time-out`; `neverError` entfernt, damit drei HTTP-Retries tatsächlich greifen |
| TASK-012 | hoch | Paperless-Backfill-Fehler in `Aggregiere Backfill-Ergebnis` beheben | Codex | Review | Kontext- und Fehlerweitergabe live korrigiert; nächsten Stundenlauf prüfen |

Aufgabenstatus: `offen`, `in Arbeit`, `blockiert`, `Review`, `erledigt`.

## Entscheidungen

| ID | Datum | Entscheidung | Begründung | Beteiligte |
|---|---|---|---|---|
| DEC-001 | 2026-07-23 | `PROJECT_COORDINATION.md` ist die zentrale Kommunikationsdatei für Mensch, Claude und Codex. | Verhindert getrennte Aufgabenlisten und Kontextverlust zwischen Werkzeugen. | Oliver, Codex |
| DEC-002 | 2026-07-23 | Anforderungen und Aufgaben erhalten stabile IDs. | Änderungen und Commits können eindeutig darauf verweisen. | Codex |
| DEC-003 | 2026-07-23 | Das statische Schnittstellen- und Prozessaudit ist in `docs/SCHNITTSTELLEN_PROZESS_AUDIT_2026-07-23.md` dokumentiert. | Claude, Codex und Oliver benötigen dieselbe priorisierte Befundbasis. | Codex |
| DEC-004 | 2026-07-23 | `ALLRIS_P8_Partei_Webseite` bleibt produktiv aktiv. | Oliver hat den aktiven Betrieb ausdrücklich bestätigt; das positive Veröffentlichungs-Gate bleibt eine getrennte Verbesserungsaufgabe. | Oliver |
| DEC-005 | 2026-07-23 | `sourceConflict` ist im kanonischen SourceLock optional. | Konfliktlose Mitteilungen dürfen nicht zu erfundenen Konflikten oder technischen Blockaden führen; vorhandene Konflikte bleiben verbindliche Quellenanker. | Codex |

## Blocker und benötigte Entscheidungen

| ID | Bezug | Blocker / Frage | Benötigt von | Status |
|---|---|---|---|---|
| BLK-001 | TASK-001 | Public API unterstützt keine neuen Spalten auf bestehenden Tabellen; sechs Fehlerfelder auf `allris_vorgaenge` müssen einmalig per n8n-UI ergänzt werden. | Oliver / n8n-UI | offen |
| BLK-002 | TASK-005 | Gewünschte Open-Source- oder proprietäre Lizenz ist nicht festgelegt. | Oliver | offen |
| BLK-003 | TASK-007 / P8 | Soll `ALLRIS_P8_Partei_Webseite` produktiv aktiv bleiben oder bis zu einem positiven Veröffentlichungs-Gate deaktiviert werden? | Oliver | erledigt – bleibt aktiv |
| BLK-004 | TASK-011 | ALLRIS-Übersichtsrequest wird aus n8n sowohl direkt als auch über `172.16.1.5:3128` nach drei Timeouts abgebrochen; Zielserver/Firewall/WAF bzw. TLS-Verbindung extern prüfen. | Infrastruktur / Goslar-Server | offen |

## Änderungs- und Übergabeprotokoll

Neueste Einträge stehen oben.

### 2026-07-23 – Codex – State-History-Tabelle angelegt

- `allris_state_history` im Projekt `CrnegVcMvlcRU0OP` vollständig und additiv
  angelegt; Live-ID `Q54kptpOrbug6bJu`.
- Live-Strukturtest prüft künftig Tabelle und alle elf Spalten.
- Die sechs Fehlerfelder auf `allris_vorgaenge` bleiben als sichtbare Warnung
  offen: Die Public API dieser n8n-Version unterstützt keine Spaltenänderung
  bestehender Tabellen, der interne Endpoint verlangt eine UI-Sitzung.
- Betroffene Dateien: `PAKET2_DB_SPEZIFIKATION.md`,
  `docs/WORKFLOW_ID_MAP.md`, `scripts/Test-AllrisWorkflows.ps1`,
  `PROJECT_COORDINATION.md`.
- Nächster Schritt: Fehlerfelder per UI ergänzen, danach Workflow-Schreibpfade
  gegen History und Fehlerfelder verdrahten.

### 2026-07-23 – Codex – SourceLock-Vertrag vereinheitlicht

- Kanonischen Vertrag unter `docs/SOURCELOCK_CONTRACT.md` dokumentiert.
- `sourceConflict` in P3b, P4, P5 und P6 als Pflichtfeld entfernt; vorhandene
  Konflikte werden weiterhin konditional geprüft und als Quellenanker genutzt.
- Strukturtest verhindert die erneute Einführung bekannter
  `sourceConflict`-Pflichtmuster und enthält einen konfliktlosen
  Regressionstest.
- Betroffene Dateien: P3b, P4, P5, P6,
  `scripts/Test-AllrisWorkflows.ps1`, `docs/SOURCELOCK_CONTRACT.md`, `README.md`
  und `PROJECT_COORDINATION.md`.
- Live-Abgleich: alle vier Workflows aktiv, veröffentlicht und strukturgleich
  mit Git.
- Tests: alle 24 Exporte, 7 Sub-Workflow-IDs und Live-Drift-Prüfung
  erfolgreich; nur die bestätigte LAN-Statuswarnung bleibt.

### 2026-07-23 – Codex – Hauptdokumentation an Live-Ablauf angeglichen

- P3e und P8 in Produktionsübersicht und Zeitplan aufgenommen.
- Zuständigkeit von P3d gegenüber P3e korrigiert.
- Paperless, LAN-Statusübersicht, Dispatcher/Watchdog, Shadow-Orchestrator und
  Reset-Wartungsworkflow dokumentiert.
- Betroffene Dateien: `README.md`, `PROJECT_COORDINATION.md`.
- Tests: Struktur- und Live-Drift-Prüfung weiterhin erfolgreich.

### 2026-07-23 – Codex – Strukturtests und Live-ID-Landkarte

- Automatische Prüfung für alle `ALLRIS_*.json` ergänzt: JSON,
  Node-Verbindungen, Sub-Workflow-IDs, Matrix-Authentifizierung und
  Git-/Live-Struktur.
- Produktive Drift in P2, P5 und P5b durch Veröffentlichung der versionierten
  Exporte beseitigt.
- Die bestätigte LAN-Abweichung der Statusübersicht wird sichtbar als Warnung
  behandelt.
- Betroffene Dateien: `scripts/Test-AllrisWorkflows.ps1`,
  `docs/WORKFLOW_ID_MAP.md`, `README.md`, `PROJECT_COORDINATION.md`.
- Tests: 24 Exporte und 7 Sub-Workflow-Referenzen lokal sowie gegen Live-n8n
  erfolgreich geprüft.
- Nächster Schritt: frischen Paperless-Lauf und einen P6-Lauf mit
  Matrix-Kandidat abnehmen.

### 2026-07-23 – Codex – Produktionsfehler P1, Paperless und P6

- P6-Node `Sende Presseartikel Matrix` verwendet das vorhandene
  `httpHeaderAuth`-Credential jetzt aktiv; Fehler werden nicht mehr
  stillschweigend über `continueRegularOutput` verschluckt.
- Paperless-Backfill erhält `vorgangKey` und Fehlerflags bis zur Aggregation;
  der unsichere Zugriff auf `$('Loop Vorgänge').first().json` wurde entfernt.
- P1-Proxywerte auf vollständige `http://`-URLs vereinheitlicht und drei
  Versuche explizit konfiguriert.
- Nachfolgende Diagnose: Der Zielpfad liefert zeitweise eine echte
  `504 Gateway Time-out`-Antwort. `neverError` wurde am Übersichtsrequest
  entfernt, damit `retryOnFail` 5xx-Antworten tatsächlich wiederholt, statt
  sie erst im nachgelagerten `codepage`-Node sichtbar zu machen.
- Betroffene Dateien: `ALLRIS_P1_Ingestion.json`,
  `ALLRIS_Paperless_Backfill.json`, `ALLRIS_P6_Bildgenerierung.json`,
  `PROJECT_COORDINATION.md`.
- Live-Abgleich: alle drei Exporte entsprechen ihren aktiven/publizierten
  n8n-Versionen.
- Tests/Validierung: JSON-Parsing, Node-Verbindungen und Zielparameter geprüft.
  P1-Live-Läufe mit und ohne Proxy scheitern weiterhin identisch am Node
  `HTTP ALLRIS Übersicht`; der Proxy ist damit nicht die alleinige Ursache.
- Offene Risiken: Paperless im nächsten Stundenlauf und P6 mit einem
  kontrollierten Matrix-Test verifizieren; P1 benötigt externe
  Netzwerk-/Zielserverdiagnose.

### 2026-07-23 – Codex – Schnittstellen- und Prozessaudit

- Alle versionierten n8n-Exporte, Workflow-Aufrufe, Zeitpläne, Statusverträge
  und externen Schnittstellen statisch geprüft.
- Zwei kritische/fachlich kritische sowie mehrere hohe und mittlere
  Inkonsistenzen dokumentiert.
- Betroffene Dateien: `docs/SCHNITTSTELLEN_PROZESS_AUDIT_2026-07-23.md`,
  `PROJECT_COORDINATION.md`.
- Tests/Validierung: alle JSON-Exporte parsebar; Node-Verbindungen,
  Sub-Workflow-Referenzen, Data-Table-Zugriffe, HTTP-Authentifizierung und
  Kandidaten-Gates ausgewertet. Kein Live-End-to-End-Test.
- Wichtigste nächste Schritte: TASK-006 und TASK-007.

### 2026-07-23 – Codex

- Zentrale Koordinationsdatei angelegt.
- Erste verbindliche Anforderungen, Aufgaben und Entscheidungen aus der
  Repository-Prüfung aufgenommen.
- Betroffene Dateien: `PROJECT_COORDINATION.md`, `README.md`.
- Validierung: Markdown-Struktur und Repository-Status lokal geprüft.
- Nächster Schritt: Datei committen und zu GitHub übertragen; danach sollten
  Claude und Codex sie vor jeder Projektänderung lesen und aktualisieren.

## Vorlage für neue Übergaben

```text
### JJJJ-MM-TT – Name

- Ziel/Aufgabe:
- Ergebnis:
- Betroffene Dateien/Workflows:
- Tests/Validierung:
- Offene Risiken oder Blocker:
- Nächster konkreter Schritt:
```
