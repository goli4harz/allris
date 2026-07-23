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
| TASK-001 | hoch | Zentrale State-History und einheitliche Fehlerfelder gemäß `PAKET2_DB_SPEZIFIKATION.md` umsetzen | Codex | erledigt | History-Tabelle und sechs Fehlerfelder live angelegt; Workflow-Verdrahtung folgt unter TASK-002 |
| TASK-002 | hoch | Dispatcher/Watchdog als zuverlässige Pipeline-Steuerung bewerten und fertigstellen | Codex | in Arbeit | P2 schreibt zentralen Fehlervertrag; History-Insert und weitere Stufen folgen |
| TASK-003 | hoch | Automatische Strukturtests für alle n8n-JSON-Exporte ergänzen | Codex | erledigt | `scripts/Test-AllrisWorkflows.ps1`, lokal und gegen Live-n8n erfolgreich |
| TASK-004 | mittel | README an tatsächlich vorhandene Stufen und Hilfsworkflows angleichen | Codex | erledigt | P3e, P8, Paperless, Status und Dispatcher/Watchdog dokumentiert |
| TASK-005 | mittel | Lizenz und Beitragsregeln festlegen | Oliver | Entscheidung nötig | gewünschte Lizenz bestimmen |
| TASK-006 | kritisch | Matrix-Authentifizierung im P6-Node `Sende Presseartikel Matrix` aktivieren und testen | Codex | Review | Authentifizierung live aktiviert; kontrollierter Matrix-Funktionstest steht noch aus |
| TASK-007 | kritisch | Fachliche Rolle und positives Veröffentlichungs-Gate für P7 festlegen | Oliver | Entscheidung nötig | Vollarchiv oder redaktioneller Kanal; Audit F-02 |
| TASK-008 | hoch | Kanonischen SourceLock-Vertrag festlegen und `sourceConflict` in allen Stufen einheitlich behandeln | Codex | erledigt | Vertrag dokumentiert; P3b/P4/P5/P6 gemeinsam live veröffentlicht und getestet |
| TASK-009 | hoch | Zeitkaskade durch Claim-/Lease-fähigen Dispatcher absichern | Codex | in Arbeit | Claim-/Lease-Vertrag und vier additive Schemafelder vorbereiten; danach manueller Doppelclaim-Test |
| TASK-010 | mittel | Workflow-ID- und Infrastruktur-Konfigurationslandkarte anlegen | Codex | erledigt | `docs/WORKFLOW_ID_MAP.md`; Live-IDs werden automatisiert geprüft |
| TASK-011 | kritisch | Wiederkehrende P1-Verbindungsabbrüche zur ALLRIS-Übersicht diagnostizieren und beheben | Codex | blockiert | Ziel liefert `504 Gateway Time-out`; `neverError` entfernt, damit drei HTTP-Retries tatsächlich greifen |
| TASK-012 | hoch | Paperless-Backfill-Fehler in `Aggregiere Backfill-Ergebnis` beheben | Codex | Review | Kontextfix live; Schedule am 23.07. neu registriert, nächsten regulären `:50`-Lauf prüfen |

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
| BLK-001 | TASK-001 | Sechs Fehlerfelder fehlten auf `allris_vorgaenge`. | Oliver / Codex | erledigt – Schema live ergänzt |
| BLK-002 | TASK-005 | Gewünschte Open-Source- oder proprietäre Lizenz ist nicht festgelegt. | Oliver | offen |
| BLK-003 | TASK-007 / P8 | Soll `ALLRIS_P8_Partei_Webseite` produktiv aktiv bleiben oder bis zu einem positiven Veröffentlichungs-Gate deaktiviert werden? | Oliver | erledigt – bleibt aktiv |
| BLK-004 | TASK-011 | ALLRIS-Übersichtsrequest wird aus n8n sowohl direkt als auch über `172.16.1.5:3128` nach drei Timeouts abgebrochen; Zielserver/Firewall/WAF bzw. TLS-Verbindung extern prüfen. | Infrastruktur / Goslar-Server | offen |

## Änderungs- und Übergabeprotokoll

Neueste Einträge stehen oben.

### 2026-07-23 – Codex – P3d an Claim-/Lease angebunden

- P3d übernimmt nur freie oder abgelaufene Vorgänge per zentralem
  Compare-and-set-Helper und lässt ausschließlich bestätigte Owner weiter.
- Fremde gültige P3- oder andere Stufen-Claims werden vor Sortierung und
  Agentenaufrufen übersprungen.
- Erfolgreicher Kettenabschluss und endgültiger QA-Block geben nur
  `ALLRIS_P3d_Agenten_Kette:<execution-id>` frei.
- Matrix-Versand ist nicht für die Freigabe zuständig; dadurch kann verlorener
  HTTP-Ausgabekontext keine falsche Zeile freigeben.
- Layout: 33 Nodes, maximal exakt 15 Nodes in einer Reihe.
- Live: aktiv, Version `fdc50fd9-5355-4edc-b970-41cf222b7dfd`.
- Tests: 25 Exporte, 11 Sub-Workflow-Referenzen, beide Release-Quellen und
  Live-Drift-Prüfung erfolgreich.
- Nächster Schritt: regulären P3/P3d-Zyklus abnehmen und danach P3e anbinden.

### 2026-07-23 – Codex – P3 als erste Claim-/Lease-Stufe

- Zentralen Subworkflow `ALLRIS_Claim_Lease` angelegt und live veröffentlicht:
  `D7cmBsy3exuOkBd9`, 7 Nodes, keine eigenständigen Schedule-/WebHook-Trigger.
- P3 überspringt fremde gültige Leases und übernimmt freie oder abgelaufene
  Claims per Compare-and-set mit anschließendem Re-Read.
- Nur bestätigte Owner erreichen die vorhandene P3-Idempotenz- und
  Verarbeitungslogik.
- Erfolgreiche Analyse sowie behandelte Summary-, Metadaten- und Parsefehler
  geben nur `ALLRIS_P3_Bewertung:<execution-id>` frei.
- Ungefangene Abbrüche behalten die 30-Minuten-Lease zur sicheren Recovery.
- Matrix und Analyse laufen weiterhin parallel; der Matrix-Zweig gibt den
  Claim bewusst nicht vorzeitig frei.
- Layout: P3 60 Nodes, stärkste Reihe 9 Nodes; Claim-Nodes in eigener lesbarer
  Reihe, unter der 15×5-Grenze.
- Live: P3 aktiv, 60 Nodes, Version
  `672e0dbe-919b-4598-9c44-d96d11f06ef3`; Helper aktiv und triggerlos.
- Tests: 25 Exporte, 9 Sub-Workflow-Referenzen, alle Strukturprüfungen grün.
- Nächster Schritt: ersten regulären P3-Lauf prüfen und danach P3d auf fremde
  aktive Claims sperren.

### 2026-07-23 – Codex – Claim-/Lease-Grundlage begonnen

- Vier additive Felder festgelegt: `claim_owner`, `claim_stage`,
  `claim_acquired_at`, `claim_expires_at`.
- Erwerb und Recovery verwenden Compare-and-set über `vorgangKey` und die
  zuvor gelesenen Claim-Werte; nach jedem Update ist ein Re-Read Pflicht.
- Standard-Lease 30 Minuten, Archiv-/Bildstufen 60 Minuten.
- Claim ist ausschließlich eine technische Exklusivsperre und ersetzt kein
  positives fachliches Eingangsgate.
- Alle vier Felder live additiv angelegt; anschließende idempotente Prüfung
  meldet das Schema vollständig.
- Inaktiven Dispatcher live importiert: `UzevGR7GafUB3dFk`, 16 Nodes in zwei
  Reihen (5 + 11), Schedule nicht aktiviert.
- Manueller Testzweig stoppt bei leerem Testschlüssel vor jedem Write, prüft
  Claim-Eigentum per Re-Read und gibt nur den eigenen Owner wieder frei.
- Ein 15-Sekunden-Fenster ermöglicht den kontrollierten parallelen
  Doppelclaim-Test.
- Atomarer Live-Test auf dem vollständig verarbeiteten Vorgang `vol_10580`
  bestanden: erster Owner änderte genau eine Zeile, zweiter stale Owner null
  Zeilen, owner-gebundene Freigabe genau eine Zeile.
- Abschluss-Read bestätigt alle vier Claim-Felder wieder leer.
- Reproduzierbarer Job `scripts/Test-AllrisClaimLease.ps1` ergänzt; ohne
  `-Apply` reine Vorschau, Cleanup im `finally`-Block.
- Betroffene Dateien: `scripts/Initialize-AllrisStateSchema.ps1`,
  `PAKET2_DB_SPEZIFIKATION.md`,
  `docs/DISPATCHER_CLAIM_LEASE_CONTRACT.md`,
  `PROJECT_COORDINATION.md`.
- Nächster Schritt: Claim-Erwerb und Freigabe zunächst in eine einzelne
  nicht unumkehrbare Produktionsstufe integrieren.

### 2026-07-23 – Codex – Paperless-Schedule neu registriert

- Execution `10047` war ein Retry des alten Workflow-Snapshots von vor dem
  Kontextfix; sie ist daher kein Abnahmetest des aktuellen Exports.
- Um 18:50 Uhr Ortszeit blieb der erwartete reguläre Lauf aus. Paperless hatte
  seit dem 22.07. keinen Stundenlauf mehr registriert, obwohl `active=true`
  gespeichert war.
- Workflow gezielt deaktiviert und sofort wieder aktiviert; aktueller Endstand:
  aktiv, `activeVersionId=ef5d66b8-d385-4e86-b223-fcc678a054d9`,
  Trigger weiterhin stündlich zur Minute `:50`.
- Strukturtest schützt jetzt zusätzlich die Wiederherstellung des
  `vorgangKey` vor `Aggregiere Backfill-Ergebnis`.
- Betroffene Dateien: `scripts/Test-AllrisWorkflows.ps1`,
  `PROJECT_COORDINATION.md`; Workflow-Inhalt blieb unverändert.
- Tests: 24 Exporte, 7 Sub-Workflow-Referenzen, alle Prüfungen erfolgreich.
- Nächster Schritt: ersten regulären Lauf nach der Reaktivierung abnehmen.

### 2026-07-23 – Codex – P3d-QA-Endfehler angebunden

- Endgültige QA-Ablehnung schreibt `FACTS_QA_FAILED`, Stufe `judgment`.
- Kein automatisches Retry-Datum: Der bestehende Prozess verlangt bewusste
  Prüfung und manuellen Status-Reset.
- History enthält Violations, Halluzinationsverdacht und Execution-ID.
- Ein History-Node unter dem vorhandenen QA-Block-Status; Abschnitt bleibt
  innerhalb drei Reihen und 15×5.
- Betroffene Dateien: `ALLRIS_P3d_Agenten_Kette.json`,
  `scripts/Test-AllrisWorkflows.ps1`, `PROJECT_COORDINATION.md`.
- Shadow-Agenten und fachliche QA-Entscheidung blieben unverändert.
- Lokal und gegen n8n geprüft: 24 Exporte, 7 Sub-Workflow-Referenzen,
  alle Prüfungen erfolgreich.
- P3d UTF-8-sicher live veröffentlicht: aktiv, 28 Nodes, Version
  `950924eb-7f76-4310-9367-282eb7d92aff`.

### 2026-07-23 – Codex – P3-Quellen- und Parsefehler angebunden

- Fehlender Summary-Quelltext und unbrauchbare Metadaten schreiben
  `SOURCE_TEXT_MISSING`, Stufe `extraction`.
- Nicht parsebares Summary-JSON schreibt `CONTENT_JSON_INVALID`, Stufe
  `analysis`.
- Alle drei vorhandenen False-Ausgänge schreiben in eine gemeinsame
  Append-History mit Retry-Metadaten.
- Ein gemeinsamer History-Node im bestehenden Fehlerbereich; 15×5-Raster
  bleibt gewahrt.
- Betroffene Dateien: `ALLRIS_P3_Bewertung.json`,
  `scripts/Test-AllrisWorkflows.ps1`, `PROJECT_COORDINATION.md`.
- Live-Rollout: P3 aktiv mit 55 Nodes und UTF-8-strukturgleich zum Export.
- Tests: alle 24 Exporte, 7 Sub-Workflow-IDs, drei History-Quellen und
  Live-Drift-Prüfung erfolgreich.
- Nächster Schritt: P3d-Fakten-/QA-Endfehler analysieren.

### 2026-07-23 – Codex – P5-Visual-Gate persistiert

- Zuvor still übersprungene Content-Gate-Fehler werden nun persistiert.
- Dynamische Zuordnung: `VISUAL_ANCHORS_MISSING`, `SOURCE_LOCK_FAILED` oder
  `CONTENT_JSON_INVALID` anhand der vorhandenen Gate-Fehlerliste.
- Content-JSON-Fehler erhalten Retry-Planung; SourceLock- und Anchor-Blockaden
  warten auf vorgelagerte Reparatur.
- Status- und History-Node liegen in der vorhandenen zweiten Reihe; Abschnitt
  bleibt deutlich innerhalb 15×5.
- Betroffene Dateien: `ALLRIS_P5_Visual_Prompt_Builder.json`,
  `scripts/Test-AllrisWorkflows.ps1`, `PROJECT_COORDINATION.md`.
- Live-Rollout: P5 aktiv mit 19 Nodes und UTF-8-strukturgleich zum Export.
- Tests: alle 24 Exporte, 7 Sub-Workflow-IDs, korrekter Gate-False-Ausgang
  und Live-Drift-Prüfung erfolgreich.
- Nächster Schritt: kontrollierten Visual-Gate-Fehlerlauf abnehmen.

### 2026-07-23 – Codex – P4-Content-Fehlervertrag angebunden

- Gemeinsamer Content-Fehlerpfad unterscheidet stabil zwischen
  `SOURCE_LOCK_FAILED` und `CONTENT_JSON_INVALID`.
- SourceLock-Blockade bleibt ohne automatisches Retry-Datum; invalider Content
  erhält exponentielle Retry-Planung.
- Beide bestehenden Fehlerquellen schreiben in eine gemeinsame Append-History.
- Ein neuer History-Node rechts neben dem Fehlerupdate; Abschnitt bleibt mit
  drei Reihen deutlich innerhalb des 15×5-Rasters.
- Betroffene Dateien: `ALLRIS_P4_Content_Reaktion.json`,
  `scripts/Test-AllrisWorkflows.ps1`, `PROJECT_COORDINATION.md`.
- Fachliche Content- und SourceLock-Gates blieben unverändert.
- Live-Rollout: P4 aktiv mit 50 Nodes und UTF-8-strukturgleich zum Export.
- Tests: alle 24 Exporte, 7 Sub-Workflow-IDs und Live-Drift-Prüfung
  erfolgreich; nur die akzeptierte LAN-Statuswarnung bleibt.
- Nächster Schritt: kontrollierten Content-/SourceLock-Fehlerlauf abnehmen.

### 2026-07-23 – Codex – P8-WordPress-Fehlervertrag angebunden

- Partei-Webseite verwendet denselben stabilen Veröffentlichungsfehlercode
  `WORDPRESS_PUBLISH_FAILED` und Stufe `publication`.
- Erfolg löscht nur einen bisherigen Veröffentlichungsfehler; andere
  Fehlerstufen bleiben erhalten.
- Erfolgs- und Fehler-History unterscheiden das Ziel
  `partei-webseite` in den Metadaten.
- Zwei neue History-Nodes kompakt in den bestehenden drei Layoutreihen
  angeordnet; 15×5-Grenze bleibt gewahrt.
- Betroffene Dateien: `ALLRIS_P8_Partei_Webseite.json`,
  `scripts/Test-AllrisWorkflows.ps1`, `PROJECT_COORDINATION.md`.
- P8 bleibt gemäß DEC-004 produktiv aktiv.
- Live-Rollout: P8 aktiv mit 18 Nodes und UTF-8-strukturgleich zum Export.
- Tests: alle 24 Exporte, 7 Sub-Workflow-IDs und Live-Drift-Prüfung
  erfolgreich; nur die akzeptierte LAN-Statuswarnung bleibt.
- Nächster Schritt: kontrollierten Partei-WordPress-Fehler-/Erfolgslauf
  abnehmen.

### 2026-07-23 – Codex – P7-WordPress-Fehlervertrag angebunden

- Veröffentlichungsfehler schreiben `WORDPRESS_PUBLISH_FAILED`, Stufe
  `publication`, Fehlerzeit und exponentielle Retry-Planung.
- Erfolg löscht zentrale Fehlerfelder nur, wenn deren bisherige Stufe
  `publication` ist; fremde Fehler bleiben erhalten.
- Erfolg und beide bestehenden Fehlerquellen schreiben Append-History.
- Zwei neue History-Nodes ohne zusätzliche Reihe kompakt im bestehenden
  15×5-Abschnitt angeordnet.
- Betroffene Dateien: `ALLRIS_P7_WordPress_Publish.json`,
  `scripts/Test-AllrisWorkflows.ps1`, `PROJECT_COORDINATION.md`.
- Fachliches Veröffentlichungs-Gate aus TASK-007 blieb unverändert.
- Live-Rollout: P7 aktiv mit 25 Nodes und UTF-8-strukturgleich zum Export.
- Tests: alle 24 Exporte, 7 Sub-Workflow-IDs und Live-Drift-Prüfung
  erfolgreich; nur die akzeptierte LAN-Statuswarnung bleibt.
- Nächster Schritt: kontrollierten WordPress-Fehler-/Erfolgslauf abnehmen.

### 2026-07-23 – Codex – P6-Matrix-Versandfehler angebunden

- Finaler Presseartikel-Versand nutzt einen echten Fehlerausgang.
- Fehlerkontext wird vorgangsbezogen wiederhergestellt und als
  `MATRIX_SEND_FAILED`, Stufe `visual`, mit exponentieller Retry-Planung
  gespeichert.
- Append-History enthält Execution-ID, Zielraum und Retry-Metadaten.
- Neue Kette kompakt rechts vom Versandnode innerhalb des 15×5-Rasters
  angeordnet.
- Betroffene Dateien: `ALLRIS_P6_Bildgenerierung.json`,
  `scripts/Test-AllrisWorkflows.ps1`, `PROJECT_COORDINATION.md`.
- Live-Rollout: P6 aktiv mit 59 Nodes und UTF-8-strukturgleich zum Export.
- Tests: alle 24 Exporte, 7 Sub-Workflow-IDs und Live-Drift-Prüfung
  erfolgreich; nur die akzeptierte LAN-Statuswarnung bleibt.
- Nächster Schritt: kontrollierten Matrix-Fehler-/Erfolgslauf abnehmen.

### 2026-07-23 – Codex – Neue Nodes grafisch ausgerichtet

- Neue Status-, Retry- und History-Nodes in P2, Paperless und P6 in getrennte
  Erfolgs-/Fehlerbahnen eingeordnet.
- Rücksprung-Nodes hinter die neuen Verarbeitungsschritte verschoben und
  History-Nodes rechts neben ihren fachlichen Statusupdates angeordnet.
- Ausschließlich `position`-Werte geändert; Parameter und Verbindungen blieben
  unverändert.
- Alle drei Workflows aktiv und UTF-8-strukturgleich live veröffentlicht.
- Tests: 24 Exporte, 7 Sub-Workflow-IDs und Live-Drift-Prüfung erfolgreich.
- Künftige neue Nodes werden nach demselben Links-nach-rechts-Schema angelegt.

### 2026-07-23 – Codex – P6-Bildfehlervertrag begonnen

- Endgültig fehlgeschlagene Bildprüfung und irreparables Bildkonzept schreiben
  additiv `IMAGE_QA_FAILED`, Stufe `image`, Fehlerzeit, Retry-Zähler und
  exponentielles `next_retry_at`.
- Bestehende Bildstatus- und Diagnosefelder bleiben unverändert erhalten.
- Strukturtest schützt beide Endfehlerpfade.
- Betroffene Dateien: `ALLRIS_P6_Bildgenerierung.json`,
  `scripts/Test-AllrisWorkflows.ps1`, `PROJECT_COORDINATION.md`.
- Gemeinsame Append-History für beide endgültigen Bildfehler ergänzt.
- Live-Rollout: P6 aktiv mit 56 Nodes und UTF-8-strukturgleich zum Export.
- Tests: alle 24 Exporte, 7 Sub-Workflow-IDs und Live-Drift-Prüfung
  erfolgreich; nur die akzeptierte LAN-Statuswarnung bleibt.
- Nächster Schritt: Matrix-Versandfehler als separaten Teilpfad behandeln.

### 2026-07-23 – Codex – Paperless-Fehlervertrag vorbereitet

- Unvollständige Backfills schreiben `PAPERLESS_IMPORT_FAILED`, Stufe
  `paperless`, Fehlerzeit sowie exponentielle Retry-Planung.
- Aktuelle Vorgangszeile wird vor Erhöhung des zentralen Retry-Zählers erneut
  gelesen.
- Erfolg und Fehler erzeugen je einen Append-Eintrag in
  `allris_state_history`; Erfolg löscht bewusst keine möglicherweise fremde
  Fehlerursache.
- Betroffene Dateien: `ALLRIS_Paperless_Backfill.json`,
  `scripts/Test-AllrisWorkflows.ps1`, `PROJECT_COORDINATION.md`.
- Live-Rollout: aktiv mit 51 Nodes, UTF-8-strukturgleich zum Export.
- Tests: alle 24 Exporte, 7 Sub-Workflow-IDs und Live-Drift-Prüfung
  erfolgreich; nur die akzeptierte LAN-Statuswarnung bleibt.
- Nächster Schritt: nächsten regulären Stundenlauf abnehmen.

### 2026-07-23 – Codex – P2 an zentralen Fehlervertrag angebunden

- Nextcloud-Archivierungsfehler schreiben additiv
  `NEXTCLOUD_UPLOAD_FAILED`, Stufe `archive`, Zeitpunkt, Meldung,
  `retry_count` und exponentielles `next_retry_at`.
- Erfolgreiche Archivierung setzt die zentralen Fehler- und Retryfelder zurück.
- Bestehende P2-Felder und Ablaufsteuerung bleiben unverändert.
- Strukturtest schützt Fehlercode, Stufe und Erfolgs-Reset.
- Betroffene Dateien: `ALLRIS_P2_Nextcloud.json`,
  `scripts/Test-AllrisWorkflows.ps1`, `PROJECT_COORDINATION.md`.
- Append-Einträge für Erfolg und Fehler in `allris_state_history` ergänzt.
- P2 aktiv und UTF-8-strukturgleich live veröffentlicht; 41 Nodes inklusive
  beider History-Pfade.
- Tests: alle 24 Exporte, 7 Sub-Workflow-IDs und Live-Drift-Prüfung
  erfolgreich; nur die akzeptierte LAN-Statuswarnung bleibt.
- Nächster Schritt: nächsten P2-Lauf auf Statusupdate und History-Zeile prüfen.

### 2026-07-23 – Codex – Fehlerfelder live angelegt

- Alle sechs additiven Fehlerfelder auf `allris_vorgaenge` angelegt:
  `last_error_code`, `last_error_message`, `last_error_stage`,
  `last_error_at`, `retry_count`, `next_retry_at`.
- Nachprüfung im Initialisierungsjob gegen eine mögliche HTTP-Cache-Antwort
  abgesichert; der unabhängige Live-Strukturtest bestätigt das vollständige
  Schema.
- TASK-001 und BLK-001 abgeschlossen.
- Betroffene Dateien: `scripts/Initialize-AllrisStateSchema.ps1`,
  `PAKET2_DB_SPEZIFIKATION.md`, `PROJECT_COORDINATION.md`.
- Nächster Schritt: additive Workflow-Schreibpfade und Dispatcher-Retry-Modell
  unter TASK-002 umsetzen.

### 2026-07-23 – Codex – Idempotenten Schema-Job vorbereitet

- `scripts/Initialize-AllrisStateSchema.ps1` ergänzt ausschließlich fehlende
  Fehlerfelder auf `allris_vorgaenge`.
- Ohne `-Apply` arbeitet der Job als reine Vorschau; nach Änderungen liest er
  das Live-Schema erneut und bricht bei Abweichungen mit Fehler ab.
- Der API-Key wird zur Laufzeit aus `N8N_API_KEY` gelesen und nicht
  versioniert.
- Betroffene Dateien: `scripts/Initialize-AllrisStateSchema.ps1`,
  `PAKET2_DB_SPEZIFIKATION.md`, `PROJECT_COORDINATION.md`.
- Nächster Schritt: Vorschau prüfen, Job manuell mit `-Apply` ausführen und
  anschließend Live-Strukturtest starten.

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
