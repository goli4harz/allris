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
| TASK-001 | hoch | Zentrale State-History und einheitliche Fehlerfelder gemäß `PAKET2_DB_SPEZIFIKATION.md` umsetzen | offen | blockiert | Data Table und Spalten in n8n anlegen; anschließend IDs dokumentieren |
| TASK-002 | hoch | Dispatcher/Watchdog als zuverlässige Pipeline-Steuerung bewerten und fertigstellen | offen | offen | Zustandsübergänge, Retry-Regeln und Parallelität festlegen |
| TASK-003 | hoch | Automatische Strukturtests für alle n8n-JSON-Exporte ergänzen | offen | offen | JSON, Node-Referenzen, Workflow-IDs und erlaubte Statuswerte prüfen |
| TASK-004 | mittel | README an tatsächlich vorhandene Stufen und Hilfsworkflows angleichen | offen | offen | insbesondere P3e und Dispatcher/Watchdog dokumentieren |
| TASK-005 | mittel | Lizenz und Beitragsregeln festlegen | Oliver | Entscheidung nötig | gewünschte Lizenz bestimmen |
| TASK-006 | kritisch | Matrix-Authentifizierung im P6-Node `Sende Presseartikel Matrix` aktivieren und testen | offen | offen | Audit F-01 |
| TASK-007 | kritisch | Fachliche Rolle und positives Veröffentlichungs-Gate für P7 festlegen | Oliver | Entscheidung nötig | Vollarchiv oder redaktioneller Kanal; Audit F-02 |
| TASK-008 | hoch | Kanonischen SourceLock-Vertrag festlegen und `sourceConflict` in allen Stufen einheitlich behandeln | offen | offen | Audit F-03 |
| TASK-009 | hoch | Zeitkaskade durch Claim-/Lease-fähigen Dispatcher absichern | offen | offen | baut auf TASK-001/TASK-002 auf; Audit F-04 |
| TASK-010 | mittel | Workflow-ID- und Infrastruktur-Konfigurationslandkarte anlegen | offen | offen | Audit F-07/F-08 |

Aufgabenstatus: `offen`, `in Arbeit`, `blockiert`, `Review`, `erledigt`.

## Entscheidungen

| ID | Datum | Entscheidung | Begründung | Beteiligte |
|---|---|---|---|---|
| DEC-001 | 2026-07-23 | `PROJECT_COORDINATION.md` ist die zentrale Kommunikationsdatei für Mensch, Claude und Codex. | Verhindert getrennte Aufgabenlisten und Kontextverlust zwischen Werkzeugen. | Oliver, Codex |
| DEC-002 | 2026-07-23 | Anforderungen und Aufgaben erhalten stabile IDs. | Änderungen und Commits können eindeutig darauf verweisen. | Codex |
| DEC-003 | 2026-07-23 | Das statische Schnittstellen- und Prozessaudit ist in `docs/SCHNITTSTELLEN_PROZESS_AUDIT_2026-07-23.md` dokumentiert. | Claude, Codex und Oliver benötigen dieselbe priorisierte Befundbasis. | Codex |

## Blocker und benötigte Entscheidungen

| ID | Bezug | Blocker / Frage | Benötigt von | Status |
|---|---|---|---|---|
| BLK-001 | TASK-001 | IDs der neu angelegten n8n Data Table und Spalten fehlen. | Oliver / n8n-Instanz | offen |
| BLK-002 | TASK-005 | Gewünschte Open-Source- oder proprietäre Lizenz ist nicht festgelegt. | Oliver | offen |

## Änderungs- und Übergabeprotokoll

Neueste Einträge stehen oben.

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
