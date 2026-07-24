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
| TASK-009 | hoch | Zeitkaskade durch Claim-/Lease-fähigen Dispatcher absichern | Codex | Review | Schema, Doppelclaim-Test und Claim-Anbindung aller zustands-/side-effect-relevanten Stufen P2–P8 einschließlich P3c und Paperless erledigt; regulären Gesamtzyklus abnehmen |
| TASK-010 | mittel | Workflow-ID- und Infrastruktur-Konfigurationslandkarte anlegen | Codex | erledigt | `docs/WORKFLOW_ID_MAP.md`; Live-IDs werden automatisiert geprüft |
| TASK-011 | kritisch | Wiederkehrende P1-Verbindungsabbrüche zur ALLRIS-Übersicht diagnostizieren und beheben | Codex | blockiert | Ziel liefert `504 Gateway Time-out`; `neverError` entfernt, damit drei HTTP-Retries tatsächlich greifen |
| TASK-012 | hoch | Paperless-Backfill-Fehler in `Aggregiere Backfill-Ergebnis` beheben | Codex | blockiert | Kontext- und Claim-Fix live; drei Scheduler-Varianten erzeugen trotz `active=true` keine Ausführung, siehe BLK-005 |

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
| BLK-005 | TASK-002 / TASK-009 / TASK-012 | Neu aktivierte n8n-Schedules erzeugen keine Ausführung: reguläres `:50`, explizites `hoursInterval=1` und kontrollierter Custom-Cron blieben ohne Execution. Workflow jeweils aktiv und `activeVersionId=versionId`; n8n Scheduler-/Worker-Logs und Dienstzustand auf dem Host prüfen beziehungsweise Dienst kontrolliert neu starten. | n8n-Infrastruktur | offen |

## Änderungs- und Übergabeprotokoll

### 2026-07-24 – Claude – ALLRIS_Claim_Lease: struktureller Fix (SplitInBatches) gegen zu breites CAS-Matching

- Ziel/Aufgabe: struktureller Fix für den im vorherigen Eintrag ("Kritischer
  Fund") beschriebenen Bug — `Erwerbe Claim CAS` matchte bei manchen von
  mehreren Items pro Ausführung zu breit (44 bzw. 6 statt 1 Treffer).
- Ergebnis: neuer Node `Loop Claims (1 pro Durchlauf)`
  (`n8n-nodes-base.splitInBatches`, `batchSize:1`) zwischen
  `Execute Workflow Trigger` und `IF Release?` eingefügt. Beide bisherigen
  Endpunkte der Kette (`Release eigener Claim` und `Bestaetige Claim`)
  verbinden jetzt zurück auf den Loop-Node statt offene Enden zu sein —
  identisches Schleifenmuster wie `Loop Vorgänge` in `ALLRIS_P3_Bewertung`
  (zwei Branches, beide zurück auf denselben SplitInBatches-Node,
  `typeVersion 3`). Dadurch läuft **jedes** Item (Acquire wie Release)
  zwingend einzeln und sequentiell durch die komplette Kette, nie mehrere
  gleichzeitig — umgeht die vermutete Mehrfach-Item-Bindungsproblematik
  strukturell, ohne deren genaue n8n-interne Ursache zu kennen.
- Betroffene Dateien/Workflows: `ALLRIS_Claim_Lease.json` (live-ID
  `D7cmBsy3exuOkBd9`, jetzt 8 statt 7 Nodes).
- Tests/Validierung: Live-GET nach PUT bestätigt Node- und
  Verbindungsstruktur exakt wie vorgesehen (`Execute Workflow Trigger` →
  `Loop Claims` → `IF Release?` → beide Zweige → zurück zu `Loop Claims`).
  **Noch KEIN echter Mehrfach-Batch-Testlauf** — die vorherige Sperre auf
  50 Zeilen muss zuerst über `ALLRIS_Einmalig_Claims_freigeben` aufgelöst
  werden, dann ein neuer P3-Lauf mit mehreren Kandidaten als eigentlicher
  Beweis, dass der Fix wirkt.
- Offene Risiken oder Blocker: `Bestaetige Claim`s Assertion
  (`items.length !== 1`) bleibt unverändert bestehen — durch die
  Einzel-Item-Verarbeitung sollte `items` an dieser Stelle jetzt immer
  genau die Re-Read-Zeilen des aktuell einen Items enthalten (0, 1 oder
  2+ bei echter Datenanomalie), nicht mehr die ganze Batch-Vermischung.
  Nicht geprüft, ob der SplitInBatches-Umbau selbst durch Mehrfachaufrufe
  aus mehreren gleichzeitigen Caller-Workflows (z.B. P3 und P4 parallel)
  neue Nebenläufigkeits-Effekte einführt — die Lease-Lock-Semantik selbst
  bleibt aber ohnehin die eigentliche Absicherung dagegen.
- Nächster konkreter Schritt: `ALLRIS_Einmalig_Claims_freigeben` ausführen,
  danach P3 (oder eine andere claim-geschützte Stufe) erneut mit
  mehreren echten Kandidaten testen und das Ergebnis hier nachtragen.

### 2026-07-24 – Claude – Kritischer Fund: Erwerbe Claim CAS matcht bei Mehrfach-Batches teils zu breit; Notfall-Freigabe-Workflow angelegt

- Ziel/Aufgabe: nach dem Rueckgabeform-Fix (siehe Eintrag unten) erneuter
  P3-Testlauf durch den Nutzer, diesmal mit 29 echten needs_summary-
  Kandidaten. Neuer Fehler: `[Claim] Re-Read lieferte 77 Zeilen.` in
  `Bestaetige Claim`.
- Befund (kritisch): per-Item-Aufschluesselung der `Erwerbe Claim CAS`-
  Ausgaben (`pairedItem`) zeigt, dass **nicht** alle 29 CAS-Updates
  fehlerhaft waren — nur Item 0 (44 statt 1 Treffer) und Item 4 (6 statt 1
  Treffer), alle uebrigen 27 liefen korrekt mit genau 1 Treffer. Ergebnis:
  **alle 50 Zeilen der gesamten `allris_vorgaenge`-Tabelle** wurden mit
  `claim_owner=ALLRIS_P3_Bewertung:10417` belegt, inklusive voellig
  unbeteiligter `content_posted`/`error`-Zeilen — nicht nur die 29
  Kandidaten. Lease bis 20:10:05 Uhr, in der Zeit konnte keine andere
  claim-geschuetzte Stufe (P2, P4-P8) irgendeine Zeile beanspruchen.
- Hypothese (nicht abschliessend bewiesen): ein n8n-internes Timing-/
  Bindungsproblem bei der Auswertung von `{{ $json.vorgangKey }}` auf dem
  `Erwerbe Claim CAS`-Node bei den ersten Aufrufen einer laengeren
  Item-Serie — die vorgangKey-Bedingung faellt dabei effektiv weg, wodurch
  nur noch `claim_owner IS NULL`/`claim_expires_at IS NULL` uebrig bleibt
  und alle zu diesem Zeitpunkt noch unclaimten Zeilen matcht. Betraf bisher
  unbemerkt vermutlich JEDEN claim-geschuetzten Mehrfach-Batch-Lauf ueber
  alle Stufen (P2-P8), nicht nur P3 — einzelne Claims (1 Item) waren nie
  betroffen, weshalb es bislang nicht auffiel.
- Sofortmassnahme: neuer Workflow `ALLRIS_Einmalig_Claims_freigeben`
  angelegt (live-ID `hIr8SR7FKIe90FTV`, inaktiv, Manual Trigger) — liest
  alle Zeilen, filtert auf gesetzten `claim_owner`, setzt die vier
  Claim-Felder pro Zeile **anhand der eindeutigen `id`-Spalte** (nicht
  `vorgangKey`) zurueck auf leer. Ein Uebertreffen dieses Cleanup-Workflows
  waere harmlos (Nullen auf bereits leere Felder setzen aendert nichts) —
  bewusst so gewaehlt, um das Cleanup nicht demselben Bug auszusetzen.
  Muss manuell in der n8n-UI ausgefuehrt werden (API kann keine Workflows
  ausloesen).
- **Noch NICHT umgesetzt**: ein struktureller Fix fuer `Erwerbe Claim CAS`
  selbst. Vorschlag (mit dem Nutzer noch nicht final bestaetigt): vor die
  Claim-Erwerb-Kette einen `SplitInBatches`(Batchgroesse 1)-Loop einbauen,
  der die Kandidaten zwingend einzeln durch die Kette schickt, statt alle
  auf einmal an den Data-Table-Node zu geben — umgeht die Mehrfach-Item-
  Bindungsproblematik strukturell.
- Betroffene Dateien/Workflows: `ALLRIS_Einmalig_Claims_freigeben.json`
  (neu), `PROJECT_COORDINATION.md`. `ALLRIS_Claim_Lease.json` selbst noch
  NICHT geaendert in diesem Eintrag.
- Offene Risiken oder Blocker: **Claim-Erwerb bei Mehrfach-Batches ist bis
  zum strukturellen Fix nicht sicher nutzbar** — kann bei jedem Lauf mit
  mehreren Kandidaten erneut die ganze Tabelle sperren. Vor jedem weiteren
  Live-Test mit mehreren Kandidaten den Freigabe-Workflow bereithalten.
- Nächster konkreter Schritt: Freigabe-Workflow einmal ausfuehren lassen,
  dann mit dem Nutzer den SplitInBatches-Strukturfix abstimmen und
  umsetzen, bevor P3 (oder eine andere claim-geschuetzte Stufe) erneut mit
  mehreren Kandidaten getestet wird.

### 2026-07-24 – Claude – ALLRIS_Claim_Lease: Rueckgabeform an runOnceForEachItem angepasst (Nachbesserung)

- Ziel/Aufgabe: Nutzer meldete live einen neuen Fehler in P3, Node
  `Erwerbe P3 Claim`: "A 'json' property isn't an object [item 0]" — direkte
  Folge des heutigen früheren Fixes (siehe Eintrag "ALLRIS_Claim_Lease:
  fehlender Node-Modus behoben").
- Ergebnis: `Validiere Claim-Anforderung` hatte `mode: runOnceForEachItem`
  gesetzt bekommen, der `return`-Ausdruck war aber unverändert
  `return [{ json: {...} }];` (Array-Form, korrekt für den alten Default
  `runOnceForAllItems`). Im Einzel-Item-Modus erwartet n8n ein einzelnes
  Objekt zurück, kein Array — daher der Fehler. Auf
  `return { json: {...} };` korrigiert.
- Betroffene Dateien/Workflows: `ALLRIS_Claim_Lease.json` (live-ID
  `D7cmBsy3exuOkBd9`, Node `Validiere Claim-Anforderung`),
  `PROJECT_COORDINATION.md`.
- Tests/Validierung: Live-GET nach PUT bestätigt die neue Rückgabeform.
  Lokale Datei per `node -e "JSON.parse(...)"` geprüft. **Kein** erneuter
  P3-Lauf mit echten Mehrfach-Kandidaten seit diesem Fix beobachtet.
- Offene Risiken oder Blocker (wichtig, unbestätigter Verdacht): der
  nachfolgende Node `Bestaetige Claim` hat ebenfalls kein `mode`-Feld
  gesetzt (Default `runOnceForAllItems`) und enthält
  `if (items.length !== 1) throw new Error(...)`. Sollte `Lese Claim
  zurueck` jetzt tatsächlich N separate Ergebnisse liefern (N = Anzahl
  Kandidaten), würde diese Assertion mit `items.length = N` erneut
  auslösen — mit genau der Fehlermeldung, die heute früh um 07:49 schon
  einmal live auftrat. Ob das so eintritt, hängt von n8n-Detailverhalten
  ab (wie Data-Table-Node-Ausgaben mehrerer Items pairedItem-technisch an
  einen nachgeschalteten Code-Node ohne eigenen Modus weitergereicht
  werden), das an dieser Stelle nicht sicher aus dem Code allein
  ableitbar ist — bewusst NICHT blind vorab geändert, um nicht erneut
  eine ungeteste Vermutung live zu deployen.
- Nächster konkreter Schritt: Nutzer bittet erneut um einen manuellen
  P3-Lauf; falls derselbe/ein neuer Fehler an `Bestaetige Claim` auftritt,
  anhand der echten Execution-Daten (`includeData=true`) diagnostizieren,
  nicht per Vermutung vorab fixen.

### 2026-07-24 – Claude – Dispatcher-Watchdog an stündliche Kaskade angepasst

- Ziel/Aufgabe: Folgefrage des Nutzers zum obigen Takt-Wechsel — muss der
  Dispatcher-Watchdog (Paket 7, 22.07.) jetzt auch schneller laufen?
- Ergebnis: zwei Anpassungen, beide inhaltlich verknüpft.
  1. Eigener `Schedule Trigger`: `hoursInterval` 6 → 1 (Minute 20 unverändert).
  2. `STALE_HOURS`-Konstante im Node `Dispatcher-Watchdog`: 24 → 6. Begründung:
     der Wert war explizit als "~5 verpasste Kaskaden-Durchläufe" relativ zum
     damaligen 5h-Takt hergeleitet (24h ≈ 5×5h). Bei jetzt stündlicher
     Kaskade hätte dieselbe 24h-Schwelle ~24 statt ~5 verpasste Durchläufe
     bedeutet — deutlich unempfindlicher als ursprünglich beabsichtigt. 6h
     erhält dieselbe "~5-6 verpasste Durchläufe"-Semantik bei neuem Takt.
  3. Zwei Code-Kommentare im selben Node an die neue Kaskadenfrequenz und
     Schwellenbegründung angepasst (reine Doku, keine Logikänderung).
- Betroffene Dateien/Workflows: `ALLRIS_Dispatcher_Watchdog.json` (live-ID
  `UzevGR7GafUB3dFk`), `PROJECT_COORDINATION.md`.
- Tests/Validierung: Live-GET nach PUT bestätigt `hoursInterval:1` und
  `STALE_HOURS = 6`. Lokale Datei per `node -e "JSON.parse(...)"` geprüft.
  Kein Live-Lauf beobachtet — der Workflow ist weiterhin `active:false`.
- Offene Risiken oder Blocker: keine inhaltliche Änderung an den 4 Checks
  selbst, nur Zeitparameter. Der Workflow ist nach wie vor nicht aktiviert;
  siehe Vorschlag im vorherigen Gespräch mit dem Nutzer, ihn zu aktivieren —
  dazu noch keine endgültige Entscheidung getroffen.
- Nächster konkreter Schritt: mit dem Nutzer klären, ob der Watchdog jetzt
  aktiviert werden soll.

### 2026-07-24 – Claude – Verarbeitungstakt P3–P8 auf stündlich erhöht

- Ziel/Aufgabe: Nutzer wollte auf Basis des needs_summary-Rückstaus schnellere
  Umlaufzeiten; explizite Weisung: "verändere alle Abläufe so, dass sie öfter
  laufen, nur P1 und P2 nicht".
- Ergebnis: `Schedule Trigger`-Node in neun Workflows von `hoursInterval: 5`
  auf `hoursInterval: 1` gesetzt, `triggerAtMinute` je Workflow unverändert
  gelassen (Reihenfolge der Kaskade innerhalb der Stunde bleibt identisch zur
  bisherigen 5h-Kaskade): `ALLRIS_P3_Bewertung` (:25), `ALLRIS_P3c_Vorgangsabschluss`
  (:28), `ALLRIS_P3d_Agenten_Kette` (:32), `ALLRIS_P3e_Kernbotschaft` (:33),
  `ALLRIS_P4_Content_Reaktion` (:35), `ALLRIS_P5_Visual_Prompt_Builder` (:45),
  `ALLRIS_P6_Bildgenerierung` (:55), `ALLRIS_P7_WordPress_Publish` (:58),
  `ALLRIS_P8_Partei_Webseite` (:59).
- Bewusst unverändert: `ALLRIS_P1_Ingestion` und `ALLRIS_P2_Nextcloud` bleiben
  bei 5h (explizite Nutzerweisung). `ALLRIS_P5b_Matrix_Headline_Reader` (schon
  15-Minuten-Poll) und `ALLRIS_Paperless_Backfill` (schon stündlich)
  unangetastet gelassen. `ALLRIS_Dispatcher_Watchdog` ist aktuell inaktiv
  (`active:false`) und wurde nicht angefasst.
- Der Claim-Lease-Mechanismus (siehe Eintrag unten) verhindert Doppelverarbeitung
  bei häufigerem Anstoßen; das eigentliche Risiko war vor dessen Fix höher, ist
  jetzt aber strukturell abgesichert.
- Betroffene Dateien/Workflows: die neun oben genannten `ALLRIS_P3*`–`ALLRIS_P8*`-
  Exporte, `PROJECT_COORDINATION.md`.
- Tests/Validierung: Live-GET nach jedem PUT bestätigt `hoursInterval:1` bei
  unveränderter `triggerAtMinute`; lokale Exporte per `node -e "JSON.parse(...)"`
  auf Gültigkeit geprüft. Kein Live-Beobachtungszeitraum über mehrere Stunden
  abgewartet.
- Offene Risiken oder Blocker: höhere Aufruffrequenz bedeutet häufigere externe
  Aufrufe (OpenAI, Nextcloud, Paperless, Matrix, WordPress) auch wenn nichts
  Neues vorliegt — bei 0 Kandidaten sollten die jeweiligen Schleifen aber ohne
  nennenswerte Zusatzkosten leer durchlaufen. Nicht geprüft, ob P1/P2 bei nur
  5h-Takt jetzt zum Engpass werden, da nachgelagerte Stufen 5x häufiger prüfen
  als neue Daten ankommen.
- Nächster konkreter Schritt: einige Stunden Betrieb beobachten (Status-
  Übersicht / Datenquellen-Tabelle), ob der needs_summary-Rückstau tatsächlich
  schneller abgebaut wird und keine der neun Stufen durch die höhere Frequenz
  auffällig wird (z. B. Rate-Limits bei OpenAI/WordPress).

### 2026-07-24 – Claude – ALLRIS_Claim_Lease: fehlender Node-Modus behoben, Live-Drift zurückgesetzt

- Ziel/Aufgabe: Nutzer meldete einen wachsenden `needs_summary`-Rückstau in
  `allris_vorgaenge` (19 von 40 Zeilen). Ursache in P3 gesucht.
- Ergebnis: `Validiere Claim-Anforderung` in `ALLRIS_Claim_Lease` hatte kein
  `mode`-Feld gesetzt und lief damit im n8n-Default `runOnceForAllItems`
  statt `runOnceForEachItem`. Der Code ist für Einzel-Item-Verarbeitung
  geschrieben (`$json`, `return [{ json: {...} }]`); im Default-Modus sah er
  bei einer Charge von N Kandidaten nur das erste Item und lieferte für den
  gesamten Lauf genau 1 Ergebnis — unabhängig von N. Live an P3 bestätigt:
  23 Kandidaten rein, 1 Claim raus (Execution 10406).
- Zusätzlich entdeckt: die **live laufende** Version von `ALLRIS_Claim_Lease`
  war von der in Git versionierten Version abgewichen, ohne Übergabe-Eintrag.
  `Lese Claim zurueck` lief live ungefiltert mit `returnAll:true` (statt der
  in Git vorhandenen `vorgangKey`-Filterung mit `limit:2`), und `Bestaetige
  Claim` hatte die Assertion `if (items.length !== 1) throw ...` gegen eine
  stille Map-Logik ohne Fehlerwurf ersetzt. Vermutlich eine Live-Notlösung
  gegen den Absturz `[Claim] Re-Read lieferte 20 Zeilen.` (siehe Execution
  10243, 07:49 Uhr), die die Ursache nicht behoben, sondern den Fehler nur
  stillgelegt hat.
- Fix: Git-Version (mit Filter + Assertion) als Basis übernommen, zusätzlich
  `"mode": "runOnceForEachItem"` auf `Validiere Claim-Anforderung` ergänzt.
  Live per API gepusht, Git und Live sind wieder identisch.
- Betroffene Dateien/Workflows: `ALLRIS_Claim_Lease.json` (live-ID
  `D7cmBsy3exuOkBd9`), `PROJECT_COORDINATION.md`.
- Tests/Validierung: Live-GET nach dem Push bestätigt `mode` und die
  Filter-/Assertion-Logik wie in Git. Backup des Live-Standes vor dem Push
  (inkl. des abgewichenen Zwischenstands) unter
  `n8n_live_backup/ALLRIS_Claim_Lease_PRE_RESYNC_*.json`. Kein Nachtest mit
  echtem Mehrfach-Batch über P3 durchgeführt (Nutzer müsste dafür P3 manuell
  auslösen, aktuell 19 wartende Zeilen als natürlicher Testfall vorhanden).
- Offene Risiken oder Blocker: Dieser Fix wurde unabhängig von Codex' TASK-009
  (Claim-Anbindung P2–P8) entwickelt und betrifft den zentralen, von allen
  Stufen gemeinsam genutzten Sub-Workflow — bitte vor der nächsten
  Claim-bezogenen Änderung diesen Eintrag lesen. Nicht geprüft, ob dieselbe
  „live weicht von Git ab"-Situation auch bei anderen Workflows vorliegt.
- Nächster konkreter Schritt: P3 (oder eine andere Claim-Stufe) einmal real
  mit mehreren wartenden Zeilen laufen lassen und bestätigen, dass mehr als
  1 Zeile pro Lauf verarbeitet wird; danach diesen Eintrag um das Ergebnis
  ergänzen.

### 2026-07-23 – Codex – n8n-Scheduler-Infrastruktur als Blocker bestätigt

- Betroffene Dateien: `ALLRIS_Paperless_Backfill.json`,
  `PROJECT_COORDINATION.md`.
- Drei kontrollierte Schedule-Varianten erzeugten keine neue Execution:
  regulär stündlich `:50`, explizites `hoursInterval=1` und ein kurzfristiger
  fünfteiliger Custom-Cron.
- Jeder Test verwendete die veröffentlichte aktive Version; temporäre
  Testminuten wurden im `finally`-Block auf den kanonischen `:50`-Schedule
  zurückgestellt.
- Paperless ist aktiv, `field=hours`, `hoursInterval=1`,
  `triggerAtMinute=50`, Version
  `c2225496-692f-4436-8e00-baf790e6d381`.
- Ohne Zugriff auf n8n Scheduler-/Worker-Logs oder den Dienst kann die reguläre
  Laufabnahme nicht im Workflow-Repository repariert oder bewiesen werden.
- BLK-005 angelegt; TASK-012 bleibt bis zur Infrastrukturbehebung blockiert.

### 2026-07-23 – Codex – Paperless-Stundenintervall explizit gesetzt

- Betroffene Dateien: `ALLRIS_Paperless_Backfill.json`,
  `scripts/Test-AllrisWorkflows.ps1`, `PROJECT_COORDINATION.md`.
- Die reguläre `:50`-Ausführung blieb trotz Aktivierung aus. Der Schedule
  enthielt nur `field=hours`, aber kein explizites `hoursInterval`.
- `hoursInterval=1` ist nun exportiert und durch einen Regressionstest
  zusammen mit `triggerAtMinute=50` abgesichert.
- Live-Rollout: aktiv, Version
  `3e110de3-9f62-4ec8-912e-b1f6a2c6b2fa`; aktiver Schedule bestätigt als
  stündlich bei Minute 50.
- Nächste reguläre Abnahme: 21:50 Uhr.

### 2026-07-23 – Codex – README auf Claim-Migrationsstand aktualisiert

- Betroffene Dateien: `README.md`, `PROJECT_COORDINATION.md`.
- Die öffentliche Betriebsbeschreibung nennt die tatsächlich claim-geschützten
  Stufen und grenzt technische Exklusivsperre von fachlicher Freigabe und
  Abschlussgarantie ab.
- Die interne Koordinationsdatei wird gemäß Olivers Vorgabe nicht im README
  verlinkt.

### 2026-07-23 – Codex – P3c an Claim-/Lease angebunden

- Betroffene Dateien: `ALLRIS_P3c_Vorgangsabschluss.json`,
  `scripts/Test-AllrisWorkflows.ps1`, `PROJECT_COORDINATION.md`.
- Abschlusskandidaten erwerben vor Repair/Markdown-Verarbeitung einen atomaren
  Claim; fremde gültige Claims werden übersprungen.
- Claim-Owner `ALLRIS_P3c_Vorgangsabschluss:<execution-id>`, Stufe
  `completion`, 60-Minuten-Lease wegen Repair- und Nextcloud-Schritten.
- Sowohl „kein Markdown nötig“ als auch der persistierte Markdown-Abschluss
  geben ausschließlich den eigenen Claim frei.
- Live-Rollout: aktiv, 20 Nodes, Version
  `32d4369f-2155-4a38-94ad-c3c940abec4b`; Scheduler neu registriert.
- TASK-009 geht in Review: P2–P8, P3c und Paperless sind claim-geschützt;
  P1 erzeugt/upsertet die Zeilen und kann vor deren Existenz keinen Row-Claim
  erwerben.

### 2026-07-23 – Codex – Paperless an Claim-/Lease angebunden

- Betroffene Dateien: `ALLRIS_Paperless_Backfill.json`,
  `scripts/Test-AllrisWorkflows.ps1`, `PROJECT_COORDINATION.md`.
- Archivierte Backfill-Kandidaten erwerben vor dem Vorgangsloop einen atomaren
  Claim; fremde gültige Claims werden übersprungen.
- Claim-Owner `ALLRIS_Paperless_Backfill:<execution-id>`, Stufe `paperless`,
  60-Minuten-Lease gegen überlappende stündliche Uploadläufe.
- Persistierter Backfill-Erfolg und Retry-Fehler geben nur den eigenen Claim
  frei; ungefangene Abbrüche behalten die Lease zur Recovery.
- Live-Rollout: aktiv, 56 Nodes, Version
  `b0e0b11e-5b49-4b83-87ee-e5ca41ea4dca`; Scheduler für `:50` neu registriert.

### 2026-07-23 – Codex – P2 an Claim-/Lease angebunden

- Betroffene Dateien: `ALLRIS_P2_Nextcloud.json`,
  `scripts/Test-AllrisWorkflows.ps1`, `PROJECT_COORDINATION.md`.
- Archivierungskandidaten erwerben vor dem Loop einen atomaren Claim; fremde
  gültige Claims werden übersprungen.
- Claim-Owner `ALLRIS_P2_Nextcloud:<execution-id>`, Stufe `archival`,
  60-Minuten-Lease für Download/Nextcloud-Operationen.
- Persistierter Erfolg und Fehler geben nur den eigenen Claim frei;
  ungefangene Abbrüche behalten die Lease zur Recovery.
- Live-Rollout: P2 aktiv, 46 Nodes, Version
  `be795faf-00d8-44d2-96df-a4ce884c46a8`; Scheduler neu registriert.
- Der vorgelagerte externe ALLRIS-`504`/Verbindungsabbruch bleibt BLK-004.

### 2026-07-23 – Codex – P7 und P8 an Claim-/Lease angebunden

- Betroffene Dateien: `ALLRIS_P7_WordPress_Publish.json`,
  `ALLRIS_P8_Partei_Webseite.json`, `scripts/Test-AllrisWorkflows.ps1`,
  `PROJECT_COORDINATION.md`.
- Beide Veröffentlichungsstufen überspringen fremde gültige Claims und
  übernehmen freie oder abgelaufene Claims atomar über `ALLRIS_Claim_Lease`.
- Claim-Owner sind workflow- und ausführungsgebunden; Stufe `publication`,
  Lease 30 Minuten.
- Erfolg und persistierter Veröffentlichungsfehler geben ausschließlich den
  eigenen Claim frei. Ungefangene Abbrüche behalten die Lease zur Recovery.
- Live-Rollout: P7 aktiv mit 34 Nodes/Version
  `0a24984c-69f1-4dfe-b581-679abc57a26a`; P8 aktiv mit 27 Nodes/Version
  `fa417b8b-eb9e-4a10-a49c-c09f9a2fae57`.
- Layout: P7 maximal 12, P8 maximal 10 Nodes pro visueller Reihe.

### 2026-07-23 – Codex – P8 gegen WordPress-Dubletten abgesichert

- Betroffene Dateien: `ALLRIS_P8_Partei_Webseite.json`,
  `scripts/Test-AllrisWorkflows.ps1`, `PROJECT_COORDINATION.md`.
- Die produktive Zielseite wurde als `https://die-partei.net/goslar/`
  verifiziert; P8 fragt deren WordPress-REST-API vor jeder Neuanlage per
  stabilem `wpSlug` ab.
- Ein vorhandener Beitrag wird über den bestehenden Erfolgs-/Datenbankpfad
  übernommen. Nur eine erfolgreiche, leere Suche erlaubt `Create a post`.
- Bei Suchfehlern wird nicht veröffentlicht; die konkrete Ursache läuft in den
  vorhandenen Veröffentlichungs-Retry-Pfad.
- Live-Rollout: P8 aktiv, 22 Nodes, stärkste visuelle Reihe 10 Nodes, Version
  `7fdafb44-8bf9-4f51-aaf7-3d4e8474e334`; Scheduler neu registriert.

### 2026-07-23 – Codex – 15-Node-Layoutgrenze automatisiert

- Betroffene Dateien: `scripts/Test-AllrisWorkflows.ps1`,
  `PROJECT_COORDINATION.md`.
- Der Strukturtest gruppiert Nodes mit bis zu 32 Pixel Y-Abstand als eine
  visuelle Zeile und meldet mehr als 15 Nodes pro Reihe als Fehler.
- Alle 25 Exporte erfüllen die Grenze; leicht versetzte Nodes können die
  Prüfung nicht durch künstlich unterschiedliche Y-Werte umgehen.

### 2026-07-23 – Codex – Paperless-Kontextwiederherstellung gehärtet

- Betroffene Dateien: `ALLRIS_Paperless_Backfill.json`,
  `scripts/Test-AllrisWorkflows.ps1`, `PROJECT_COORDINATION.md`.
- Aus Ausführung `10047` wurde strukturell bestätigt, dass ein alter
  Ergebniszweig den `vorgangKey` vor der Aggregation verlor.
- Der Log-Node verwendet nun ausschließlich item-verknüpfte Kontexte aus
  Titel- und Downloadprüfung; ein unsicherer `first()`-Fallback bleibt verboten.
- Fehlt der Schlüssel trotzdem, bricht der Zweig explizit ab, statt Erfolg oder
  Fehler einem möglicherweise falschen Vorgang zuzuordnen.
- Live-Rollout: Paperless aktiv, 51 Nodes, Version
  `f0f2fdc0-78c4-4fe4-b24d-2a56a233ea66`; Scheduler erneut registriert.
- Reguläre Abnahme beim nächsten `:50`-Lauf steht aus.

### 2026-07-23 – Codex – Scheduler neu registriert und P8-Iststand bereinigt

- Betroffene Dateien: `ALLRIS_P8_Partei_Webseite.json`,
  `docs/SCHNITTSTELLEN_PROZESS_AUDIT_2026-07-23.md`,
  `PROJECT_COORDINATION.md`.
- Paperless, P7 und P8 waren laut API aktiv und veröffentlicht, erzeugten nach
  ihren erwarteten Terminen aber keine neuen Ausführungen.
- Alle drei Workflows wurden kontrolliert deaktiviert und mit JSON-Request
  wieder aktiviert; `active=true` und `activeVersionId=versionId` sind bestätigt.
- Der P8-Export und das Audit spiegeln den bereits mit DEC-004 bestätigten
  produktiven Aktivstatus jetzt korrekt wider.
- Reguläre Abnahmefenster: Paperless `:50`, P7 `:58`, P8 `:59`.

### 2026-07-23 – Codex – P8 berücksichtigt Veröffentlichungs-Retry

- Betroffene Dateien: `ALLRIS_P8_Partei_Webseite.json`,
  `scripts/Test-AllrisWorkflows.ps1`, `PROJECT_COORDINATION.md`.
- P8 überspringt fehlgeschlagene Veröffentlichungen nun bis `next_retry_at`,
  gezielt begrenzt auf `last_error_stage=publication`.
- Aktivstatus, Zeitplan, 18 Nodes, Verbindungen und Layout blieben unverändert.
- Live-Rollout: P8 aktiv, Version
  `2e56895c-3e25-43ad-a688-6c2a6c476a84`.
- Für eine Dublettenprüfung fehlt noch eine verlässlich bekannte Ziel-REST-URL;
  die Tabelle enthält bislang keinen gespeicherten P8-Veröffentlichungslink.

### 2026-07-23 – Codex – P7 gegen WordPress-Dubletten abgesichert

- Betroffene Dateien: `ALLRIS_P7_WordPress_Publish.json`,
  `scripts/Test-AllrisWorkflows.ps1`, `PROJECT_COORDINATION.md`.
- Vor `Create a post` fragt P7 WordPress mit dem stabilen `wordpressSlug` ab.
- Ein bereits vorhandener Beitrag wird über den bestehenden Erfolgs- und
  Datenbankpfad übernommen, statt als `-2`-Slug erneut veröffentlicht zu werden.
- Nur eine erfolgreiche, leere Slug-Suche erlaubt die Neuanlage. Ein Suchfehler
  blockiert die Veröffentlichung und läuft in den bestehenden Retry-Fehlerpfad.
- Vier Nodes ergänzt; P7 bleibt mit 29 Nodes im vereinbarten 15-x-5-Raster.
- Live-Rollout: P7 aktiv, exakt fünf grafische Zeilen mit maximal 12 Nodes,
  Version `3baa8f58-37ab-4228-92aa-09a8b86796f0`.
- Nächster Schritt: regulären P7-Lauf beobachten; Claim-/Lease erst danach
  ergänzen, damit die Veröffentlichungslogik nicht gleichzeitig geändert wird.

### 2026-07-23 – Codex – P7 berücksichtigt Veröffentlichungs-Retry

- Betroffene Dateien: `ALLRIS_P7_WordPress_Publish.json`,
  `scripts/Test-AllrisWorkflows.ps1`, `PROJECT_COORDINATION.md`.
- `Filter WordPress-Kandidaten` überspringt nun fehlgeschlagene
  Veröffentlichungen bis zum in `next_retry_at` gespeicherten Zeitpunkt.
- Die Sperre gilt gezielt für `last_error_stage=publication`; Fehler anderer
  Stufen und reguläre Kandidaten werden dadurch nicht zurückgehalten.
- Regressionstest ergänzt; alle 25 Exporte und 19 Sub-Workflow-Referenzen
  einschließlich Live-Abgleich erfolgreich.
- Live-Rollout: P7 aktiv, 25 Nodes, Version
  `ddbce356-d5f5-4a7d-927b-f7382e208c6d`; Layout unverändert.
- Nächster Schritt: vor Claim-/Lease-Einbau eine WordPress-Slug-Abfrage zur
  sicheren Wiederaufnahme nach unklaren HTTP-Timeouts konzipieren.

Neueste Einträge stehen oben.

### 2026-07-23 – Codex – P6 an Claim-/Lease angebunden

- Claim-Erwerb erfolgt erst nach Sortierung und Mengenbegrenzung; weggefilterte
  Bildkandidaten werden nicht unnötig gesperrt.
- Bild-API, Compositing, Matrix-Bildversand und Nextcloud erhalten wegen ihrer
  Laufzeit eine 60-Minuten-Lease.
- Vier owner-gebundene Freigaben: `image_composed`, endgültige Bildprüfung,
  endgültiges Bildkonzept und SourceLock-Blockade.
- Der parallele Presseartikel-/Matrix-Benachrichtigungsast gibt nicht vorzeitig
  frei; nach `image_composed` verhindert der Bildstatus eine erneute P6-Auswahl.
- Layout: 64 Nodes, maximal 13 Nodes in einer Reihe.
- Live: aktiv, Version `cd24828c-e266-4147-8987-4af4c1be9ae6`.
- Tests: 25 Exporte, 19 Sub-Workflow-Referenzen, vier eindeutige
  Release-Quellen und Live-Drift-Prüfung erfolgreich.
- Nächster Schritt: regulären Zyklus abnehmen; Veröffentlichung P7/P8 erst nach
  gesonderter Claim-/Side-Effect-Prüfung anbinden.

### 2026-07-23 – Codex – P5 an Claim-/Lease angebunden

- Claim-Erwerb erfolgt erst nach dem bestehenden Visual-Status-Filter; das
  menschliche Headline-/Matrix-Gate bleibt unverändert.
- Freie oder abgelaufene Visual-Kandidaten werden atomar übernommen, fremde
  gültige Claims übersprungen.
- Erfolgreicher Prompt-Write und bestehender Visual-Gate-Fehler geben nur
  `ALLRIS_P5_Visual_Prompt_Builder:<execution-id>` frei.
- Claim-Stufe `visual`, Lease 30 Minuten.
- Layout: 24 Nodes, maximal 7 Nodes in einer Reihe.
- Live: aktiv, Version `94a0fbe7-43a8-4448-8e1b-79bfa461e295`.
- Tests: 25 Exporte, 17 Sub-Workflow-Referenzen, beide Release-Quellen und
  Live-Drift-Prüfung erfolgreich.
- Nächster Schritt: regulären Zyklus abnehmen und P6 mit längerer Bild-Lease
  anbinden.

### 2026-07-23 – Codex – P4 an Claim-/Lease angebunden

- Claims gelten ausschließlich für den produktiven `needs_content`-Pfad;
  sechs vorhandene Repair-/Alert-Nebenpfade blieben unverändert.
- Fremde gültige Claims werden vor Sortierung und Content-Erzeugung
  übersprungen; freie/abgelaufene Claims werden atomar übernommen.
- `Update Final Status` und der gemeinsame Content-/SourceLock-Fehlerabschluss
  geben nur `ALLRIS_P4_Content_Reaktion:<execution-id>` frei.
- Claim-Stufe `content`, Lease 30 Minuten.
- Layout: 55 Nodes, maximal 11 Nodes in einer Reihe.
- Live: aktiv, Version `449a19d4-dc0d-49f0-b7b2-2295876eb6a1`.
- Tests: 25 Exporte, 15 Sub-Workflow-Referenzen, beide Release-Quellen und
  Live-Drift-Prüfung erfolgreich.
- Nächster Schritt: regulären Zyklus abnehmen und P5 anbinden.

### 2026-07-23 – Codex – P3e an Claim-/Lease angebunden

- P3e übernimmt freie oder abgelaufene Kernbotschaft-Kandidaten atomar und
  überspringt fremde gültige Claims.
- Satire-Erfolg und behandelter Satirefehler laufen bereits durch denselben
  Datenbankabschluss; genau dort erfolgt die owner-gebundene Freigabe.
- Claim-Owner: `ALLRIS_P3e_Kernbotschaft:<execution-id>`, Stufe `approval`,
  Lease 30 Minuten.
- Layout: 22 Nodes, maximal 11 Nodes in einer Reihe.
- Live: aktiv, Version `c8e652d8-baf6-4614-ae33-2edebb518732`.
- Tests: 25 Exporte, 13 Sub-Workflow-Referenzen und Live-Drift-Prüfung
  erfolgreich.
- Nächster Schritt: regulären P3/P3d/P3e-Zyklus abnehmen und anschließend P4
  als nächste nicht veröffentlichende Stufe anbinden.

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
