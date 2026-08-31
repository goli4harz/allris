# ALLRIS

## Was ist das – und was bringt es mir?

**Kurz gesagt:** Diese Software beobachtet automatisch das Goslarer Ratsinformationssystem (ALLRIS) und macht aus neuen politischen Vorgängen – Anträgen, Anfragen, Mitteilungen der Verwaltung – automatisch fertige, satirische Social-Media-Beiträge samt passendem Bild. Ohne dass jemand manuell Ratsdokumente durchforsten oder Beiträge von Hand schreiben muss.

Diese Dokumentation richtet sich zunächst an Sie als kommunalpolitisch Aktive, die wissen wollen, was das Werkzeug bringt – nicht an Techniker. Der technische Teil weiter unten ist für die Wartung gedacht und kann übersprungen werden.

### Was das konkret für Sie bedeutet

- **Sie verpassen nichts mehr.** Jeder neue Vorgang im Ratsinformationssystem wird automatisch erkannt – auch dann, wenn gerade niemand Zeit hatte, selbst nachzuschauen.
- **Kein manuelles Wälzen von Sitzungsunterlagen.** Die Software liest die oft langen, sperrigen Verwaltungsdokumente, fasst sie zusammen und bewertet, ob ein Vorgang politisch relevant und öffentlichkeitswirksam ist.
- **Fertige Social-Media-Beiträge, ohne dass jemand am Schreibtisch sitzen muss.** Website-Artikel sowie Facebook-, Instagram- und Mastodon-Beiträge werden inklusive Bild automatisch erstellt und veröffentlicht – im typischen, satirischen Ton der PARTEI.
- **Kontinuierliche Präsenz ohne Mehraufwand.** Statt „wir posten, wenn mal wieder wer Zeit findet" gibt es einen verlässlichen, mehrmals täglich laufenden Automatismus.
- **Der Mensch bleibt an den wichtigen Stellen im Boot.** Bei der Auswahl der besten Schlagzeile für ein Sharepic wird kurz per Chat-Umfrage nachgefragt – kein Beitrag geht ganz ohne redaktionelle Kontrolle raus.
- **Mehr Zeit für echte politische Arbeit.** Der Zeitaufwand, der sonst für Social-Media-Redaktion draufgeht, entfällt weitgehend.

### Wie das grob funktioniert (ohne Technik-Details)

1. Die Software schaut regelmäßig ins Ratsinformationssystem und merkt sich neue Vorgänge.
2. Zugehörige Dokumente werden automatisch geladen und ausgewertet.
3. Eine KI entscheidet, ob ein Vorgang interessant genug für eine öffentliche Reaktion ist.
4. Für relevante Vorgänge werden automatisch Texte für Website, Facebook, Instagram und Mastodon geschrieben.
5. Falls ein Bild (Sharepic) sinnvoll ist, wird passendes Bildmaterial automatisch erzeugt – die beste Schlagzeile dafür wird kurz per Chat abgefragt.
6. Alles wird zeitversetzt und automatisch veröffentlicht.

Für alles Weitere – wie das im Detail technisch aufgebaut ist – richtet sich der Rest dieser Dokumentation an Personen, die das System warten oder weiterentwickeln.

## Technische Dokumentation

n8n-Automatisierungspipeline für DIE PARTEI Kreisverband Goslar. Überwacht das Goslarer Ratsinformationssystem ALLRIS, bewertet neue Vorgänge, und generiert daraus automatisiert satirische Social-Media-Inhalte und Sharepics.

## Produktions-Pipeline (P1–P9 + P3b/P3c/P3d/P3e + P8b)

Das sind die Dateien, die tatsächlich live laufen (n8n Schedule Trigger, alle 5 Stunden, zeitversetzt) und reale Vorgänge von der ALLRIS-Erfassung bis zur WordPress-Veröffentlichung durchreichen:

| Datei | Stufe | Warum diese Stufe eigenständig ist |
|---|---|---|
| `ALLRIS_P1_Ingestion.json` | Neue Vorgänge aus ALLRIS erfassen | Einziger Schreibzugriff auf die ALLRIS-Quelle; erkennt neue/geänderte Vorgänge und legt die Basiszeile in der Data Table an |
| `ALLRIS_P2_Nextcloud.json` | Dokumente herunterladen, in Nextcloud ablegen | Dokument-Download ist der langsamste/instabilste Schritt (externe PDFs) — getrennt von der Bewertung, damit ein Download-Fehler nicht die KI-Analyse blockiert |
| `ALLRIS_P3_Bewertung.json` | KI-Zusammenfassung + Relevanz-Analyse | Idempotenz-Guard, Folgevorgang-Kettenauflösung, Metadaten-Validierung, Summary-Beschaffung (inkl. Nextcloud/Tika-Fallback), KI-Analyse (Relevanz/"Sprengstoff"/Empfehlung). Endet an der bestehenden `contentStage`-Weiche (`needs_content`/`watching`/`ignored`) — bewusst schlank gehalten, seit 2026-07-19 (siehe unten) |
| `ALLRIS_P3b_Repair_SourceLock_VisualGuard.json` | Sub-Workflow: repariert unvollständige SourceLock/VisualAnchors | Kein eigener Trigger — wird von P3c aufgerufen, wenn eine Zeile unvollständige Daten hat, statt die teure P3-Analyse komplett zu wiederholen |
| `ALLRIS_P3c_Vorgangsabschluss.json` | Repair-Aufruf + Summary-Markdown/Nextcloud-Upload | Eigenständig seit 2026-07-19 (vorher Teil von P3): konsolidiert den Repair-Trigger und das Markdown-Archiv in einer schlanken, unabhängig testbaren Stufe |
| `ALLRIS_P3d_Agenten_Kette.json` | Eignungs-/Fakten-/QA-/Lern-Agent-Kette | Entscheidet, ob ein Sharepic-fähiges Thema vorliegt, extrahiert belegbare Fakten, prüft QA und speichert Lernbeispiele |
| `ALLRIS_P3e_Kernbotschaft.json` | Kernbotschaft und Satire-Varianten | Ruft den Satire-Agenten auf und erzeugt die Varianten, aus denen die Text- und spätere Matrix-Bildauswahl hervorgehen |
| `ALLRIS_P4_Content_Reaktion.json` | Generiert Social-Media-Inhalte (Website, Facebook, Instagram, Reaktion) | Trennt Text-Content-Erzeugung von der Bewertung (P3), damit Content unabhängig nachbearbeitet/wiederholt werden kann |
| `ALLRIS_P5_Visual_Prompt_Builder.json` | Baut Bild-Prompt (Motiv, Headline-Varianten, Subline) | Eigene Stufe, weil die Headline-Auswahl einen menschlichen Zwischenschritt braucht (Matrix-Umfrage) — kann nicht in einem Durchlauf mit der Bildgenerierung stehen |
| `ALLRIS_P5b_Matrix_Headline_Reader.json` | Liest Matrix-Antworten auf Headline-Auswahl | Reply-Hälfte von P5s Umfrage; eigener 15-Minuten-Trigger, weil Matrix-Antworten asynchron zur 5-Stunden-Pipeline eintreffen |
| `ALLRIS_P6_Bildgenerierung.json` | Erzeugt und komponiert das Sharepic | Größte Datei: Bild-API-Aufruf, Compositing, Qualitätsprüfung, Nextcloud-Upload, Matrix-Post — bewusst als ein Block, da diese Schritte eng an denselben Bildzustand gekoppelt sind |
| `ALLRIS_P7_WordPress_Publish.json` | Veröffentlicht auf WordPress (golietz.de) | Letzter, unumkehrbarer Schritt — eigene Stufe, damit ein WordPress-Fehler isoliert sichtbar bleibt und nicht mit Bildgenerierungsfehlern vermischt wird |
| `ALLRIS_P8_Partei_Webseite.json` | Legt Entwurf auf der Partei-Webseite (die-partei.net/goslar) an | Seit 2026-07-26 **nur noch Entwurfs-Erstellung** (`status='draft'`): Bild-Upload + Post anlegen laufen für jeden fertigen Vorgang sofort, das eigentliche Live-Schalten wurde in P8b ausgelagert |
| `ALLRIS_P8b_Tagesveroeffentlichung.json` | Schaltet genau einen Entwurf/Tag live | Neu 2026-07-26 (Nutzerwunsch: gleichmäßiger Veröffentlichungsrhythmus statt Batch-Postings). Wählt den ältesten offenen Entwurf (`wordpressGoslarDraftId` gesetzt, `wordpressGoslarPosted` noch falsch), setzt per WordPress-REST-API `status=publish`. Erst danach lesen P9/P10 den echten Live-Link |
| `ALLRIS_P9_Mastodon_Publish.json` | Veröffentlicht auf Mastodon | Postet Bild + Text + KI-generierte und feste Hashtags (`#meingoslar #goslar #meinklüngelkannmehr #prioritätenproblem`); wartet zwingend auf `wordpressGoslarPosted` + `wordpressGoslarPostLink` (also auf P8b, nie auf P8 direkt), damit der verlinkte Artikel beim Posten schon wirklich live ist |

`ALLRIS_P10_Instagram_Publish.json` existiert bereits (26 Nodes, gleiches Claim-/History-Muster wie P9, Graph-API Media-Container→Publish-Flow, nutzt dieselbe P8-Bild-URL), ist aber **inaktiv** — wartet auf Instagram Business Account ID + Access Token vom Nutzer (siehe Platzhalter direkt in den beiden `graph.facebook.com`-URLs im Workflow).

**Aktueller Stand (2026-07-26):** Nach einer kompletten DB-Leerung (Neustart mit frischer ALLRIS-Erfassung) wurden beim ersten End-to-End-Testlauf mehrere reale Bugs gefunden und behoben, plus zwei Architekturänderungen auf Nutzerwunsch umgesetzt:

- **KI-JSON-Reparatur pipeline-weit:** eine wiederverwendbare `__repairJsonText`/`__robustJsonParse`-Funktion (schließt einen vom Modell offen gelassenen String vor dem nächsten `"key":`, verwirft überzählige schließende Klammern) wurde in alle 15 Erstparse-Stellen für rohe KI-Antworten eingebaut (P3, P3b, P4, P6, QA-/Satire-/Fakten-/Bild-/Eignungs-Agent). Auslöser: ein einzelner nicht geschlossener String + eine überzählige `]` in einer P3-Analyseantwort blockierte einen Vorgang komplett.
- **P3 Auto-Retry:** vier bislang einmalig-fatale Fehlerarten (`summary_input_error`, `metadata_error`, KI-Summary-Parsefehler, KI-Analyse-Parsefehler) bekommen jetzt bis zu 3 automatische Versuche mit exponentiellem Backoff, bevor die Zeile dauerhaft auf `error` bleibt. `archiving_failed` bleibt bewusst manuell (P2 hat dafür schon 10 eigene Versuche hinter sich).
- **P2 Fehlermeldung:** `Markiere Upload Fehler` las ein nie gesetztes Feld (`_downloadError` statt `_downloadRejectedReason`) — jeder Download-Fehler zeigte pipeline-weit nur „unbekannt“ statt der echten Ursache.
- **P6 Fehlerbehandlung:** OpenAI-Bildgenerierungs-/QA-Fehler wurden nicht abgefangen und rissen die ganze Ausführung ab (inkl. hängendem Claim); jetzt sauber erfasst und über `last_error_*`/Claim-Freigabe behandelt.
- **P8-Bildkette, drei getrennte Ursachen live gefunden und behoben:** (1) ein fehlgeschlagener Medien-Upload wurde nie protokolliert, (2) der native n8n-WordPress-Node übernahm `featured_media` beim Post-Erstellen zuverlässig **nicht** — ersetzt durch eine rohe HTTP-Anfrage an dieselbe REST-Route, (3) auf Nutzerwunsch wird das Bild zusätzlich direkt als `<img>` in den Artikeltext eingebettet, weil sich nicht jedes Theme auf das Beitragsbild verlässt.
- **P8/P8b-Split + P9-Hashtags:** siehe Tabelle oben.
- **Status-Übersicht** zeigt den neuen Entwurfs-Zwischenzustand jetzt separat (`◐`) statt ihn wie „nichts passiert“ aussehen zu lassen.
- Mehrere **Einmalig-Wartungsworkflows** entstanden dabei (siehe Abschnitt unten) für den Fall, dass Live-Posts von Hand gelöscht werden und die Data Table neu synchronisiert werden muss.

**Aktueller Stand (2026-07-19):** P3 wurde von 96 auf 54 Nodes verschlankt, indem zwei größtenteils unabhängige Verantwortlichkeiten (Repair+Archivierung, KI-Urteils-Kette) in die neuen Stufen `P3c_Vorgangsabschluss` und `P3d_Agenten_Kette` ausgelagert wurden — motiviert dadurch, dass P3 als Monolith zu unübersichtlich zum Debuggen wurde. Alle drei live getestet und schrittweise scharf geschaltet (Details siehe Git-Historie der jeweiligen Commits). Dabei zwei echte, vom Split unabhängige Bugs gefunden: die Spalte `eignungsAgentJson` existierte nie wirklich, wodurch der komplette Eignungs-Entscheidung-Schreibvorgang (inkl. `sharepicNeedStage`) seit dessen Einführung am Vortag silent fehlschlug; und ein Nextcloud-Upload-Node, dessen leerer Rückgabewert einen nachfolgenden DB-Schreibvorgang um seinen Row-Key brachte (gleiche Bugklasse wie ein früherer Matrix-Vorfall in P2). Zusätzlich wurde die n8n-Instanz aufgeräumt: 329 historische ALLRIS-Workflow-Versionsstände gelöscht (481→152 Workflows insgesamt) sowie 2 nie verdrahtete Data-Table-Spalten (`bildAgentJson`, `headlineChoiceProcessedAt`, 116→114 Spalten).

Vorherige Änderung (2026-07-18): mehrere Live-Bugs in P1 und P4 behoben (Content-Verlust nach dem Matrix-Post in P4, veraltete `visualStage`-Werte aus abgelösten Workflow-Versionen, dauerhaftes Alert-Spamming im "blockierte Vorgänge"-Dashboard, eine feste 2-Seiten-Grenze beim ALLRIS-Übersicht-Scraping in P1) sowie ein echter Zeitplan-Fehler in P7 (lief bisher *vor* P4 im selben 5-Stunden-Zyklus — behoben durch Verschieben von P7 ans Ende der Kaskade).

**Zeitplan-Kaskade, live verifiziert 2026-07-26** (P1/P2 alle 5h, P3–P9 stündlich, P8b täglich): `P1=:05(5h) → P2=:15(5h) → P3=:05 → P3d=:13 → P4=:21 → P3c=:28 → P5=:29 → P3e=:33 → P6=:37 → P7=:45 → P8=:52 → P9=:58` und separat `Paperless-Backfill=:00(1h)`, `P8b=täglich 06:00`, `P9=täglich 17:30`. **Hinweis:** die tatsächliche Reihenfolge weicht inzwischen von der ursprünglich dokumentierten Absicht (P3→P3c→P3d→P3e→P4) ab — P3d läuft heute vor P4, P3c/P5/P3e danach. Nicht im Rahmen der Dokumentationsaktualisierung geprüft, ob das noch der beabsichtigten Datenabhängigkeit entspricht. Atomare Claim-/Lease-Sperren verhindern in P2, P3, P3c, P3d, P3e, P4–P9 sowie im Paperless-Backfill, dass parallele Läufe denselben Vorgang gleichzeitig bearbeiten. Ein Claim ersetzt keine fachliche Eingangsvoraussetzung und garantiert nicht den Abschluss der vorherigen Stufe.

## Hilfs- und Betriebsworkflows

- `ALLRIS_Paperless_Backfill.json` läuft stündlich zur Minute `:00` (live
  verifiziert 2026-07-26) und überträgt archivierte Originaldokumente nach Paperless.
- `ALLRIS_Status_Uebersicht.json` stellt die im LAN verwendete
  Statusübersicht bereit.
- `ALLRIS_Dispatcher_Watchdog.json` ist inaktiv in der Live-Instanz vorhanden.
  Sein Schedule steuert die Pipeline noch nicht; ein getrennter Manual-Zweig
  dient dem kontrollierten Claim-/Lease- und Doppelclaim-Test.
- `ALLRIS_Claim_Lease.json` ist der veröffentlichte, triggerlose Sub-Workflow
  für atomaren Claim-Erwerb, Re-Read und owner-gebundene Freigabe. Die
  Stufen P2, P3, P3c, P3d, P3e und P4–P8 sowie der Paperless-Backfill
  verwenden ihn; er kann nicht selbstständig starten.
- `ALLRIS_Orchestrator_Shadow.json` bleibt ein inaktiver manueller
  Vergleichsworkflow.
- `ALLRIS_Reset_Paperless_Backfill_Marker.json` ist ein lokaler,
  nicht produktiv importierter Wartungsworkflow.
- `ALLRIS_Einmalig_ContentStage_Reset.json`, `ALLRIS_Einmalig_Claims_freigeben.json`,
  `ALLRIS_Einmalig_WordPress_Status_Reset.json`, `ALLRIS_Einmalig_Mastodon_Status_Reset.json` —
  manuelle Reparaturwerkzeuge (Manual Trigger, inaktiv, per Hand über "Execute workflow"
  auszulösen). Die letzten beiden wurden 2026-07-26 nötig, weil live veröffentlichte
  WordPress-Beiträge/Mastodon-Toots von Hand außerhalb der Pipeline gelöscht wurden, während
  die Data Table weiter `wordpressPosted`/`wordpressGoslarPosted`/`mastodonPosted=true` zeigte
  — ohne Reset hätten P7/P8/P9 diese Zeilen für immer als "schon erledigt" übersprungen.

## State-Management-Modell

Jede Zeile in der Data Table `allris_vorgaenge` trägt mehrere unabhängige Zustandsfelder, die den Fortschritt entlang orthogonaler Achsen beschreiben:

- **`contentStage`** (+ `contentErrorReason` bei Fehlern) — wie weit die Text-Content-Erzeugung ist (`needs_summary` → `content_generated` → `content_posted`, oder `error`)
- **`sharepicNeedStage`** — ob ein Sharepic für diesen Vorgang überhaupt sinnvoll/zulässig ist (`not_applicable` / `topic_ok` / `topic_error`), seit 2026-07-19 die alleinige, maßgebliche Entscheidung des `ALLRIS_Eignungs_Agent` (siehe unten) plus deterministischer SourceLock-/VisualAnchor-/Guard-Prüfung danach, die nur noch *verschärfen*, nie überstimmen kann
- **`headlineChoiceStage`** — wie weit die Matrix-Umfrage zur Headline-/Satire-Varianten-Auswahl ist (`awaiting_headline_choice` → `headline_selected`, oder `satire_agent_failed`)
- **`visualPromptStage`** — wie weit der Bild-Prompt-Bau ist (`needs_prompt` → `prompt_ready`, oder `prompt_error`), von P4→P5→P6 gemeinsam gepflegt
- **`imageStage`** — wie weit die eigentliche Bildgenerierung ist (`not_started` → `qa_pending` → `composed` …)

Das ersetzt zwei ältere Modelle: zuerst ein zwei-Felder-Modell (`status`, `visualStatus`), das de facto drei Zustände in zwei Spalten kodierte und wiederholt zu Bugs führte (Migration 2026-07-17/18); danach ein einzelnes `visualStage`-Feld, das von **drei unabhängig entstandenen, teils widersprüchlichen Formeln** parallel beschrieben wurde (P3 direkt nach der Analyse, P3 nach der Headline-Umfrage, P4 nach der Content-Erzeugung — mit jeweils eigenen, leicht unterschiedlichen Schwellenwerten auf denselben Zahlen). **Am 2026-07-19 aufgelöst**: der neue `ALLRIS_Eignungs_Agent` trifft die "braucht dieser Vorgang ein Sharepic?"-Entscheidung als echtes redaktionelles Ermessen (KI-Agent, kein Schwellenwert), `visualStage` wurde in die drei oben genannten, klar getrennten Felder aufgeteilt. Ein manuelles Force-Reset läuft weiterhin über zwei eigene Boolean-Spalten (`visualForceReset`, `imageForceReset`) statt über magische String-Werte.

Der verbindliche Quellenvertrag ist in
[`docs/SOURCELOCK_CONTRACT.md`](docs/SOURCELOCK_CONTRACT.md) dokumentiert.
`sourceConflict` ist optional: Ein leerer Wert darf einen konfliktlosen,
ansonsten vollständig belegten Vorgang nicht blockieren.

## Agenten-System (produktiv seit 2026-07-18/19)

Sechs einzeln zuständige KI-Agenten plus ein Vergleichs-Werkzeug, die frühere, über P3/P3b/P4/P5 verstreute Prüf- und Generierungslogik konsolidieren. **War bis 2026-07-17 reiner Schattenbetrieb** (parallel mitgelaufen, ohne das Live-Ergebnis zu beeinflussen) — seit dem Cutover am 2026-07-18 sind fünf der sechs Agenten echte, aufrufende Bestandteile der Pipeline, nicht mehr nur Vergleichsdaten:

- `ALLRIS_QA_Agent.json` — konsolidierter Prüf-Agent (SourceLock/VisualAnchors-Vollständigkeit, Halluzinationsprüfung), aufgerufen von P3d. Blockiert eine Zeile aktiv (`contentStage=error`, `qa_blocked` + Matrix-Alert), wenn die Prüfung scheitert.
- `ALLRIS_Fakten_Agent.json` — reine Fakten-Extraktion ohne Interpretation, aufgerufen von P3d als Grundlage für Satire- und Bild-Agent. Ersetzt P3s alte inline SourceLock-Extraktion vollständig.
- `ALLRIS_Satire_Agent.json` — generiert mehrere Satire-Varianten in unterschiedlicher Schärfe inkl. Headline/Subline, aufgerufen von P3d; die Text-Variante wird automatisch gewählt, die Bild-Variante über eine echte Matrix-Umfrage (P3d sendet, P5b liest die Antwort).
- `ALLRIS_Bild_Agent.json` — baut Bild-Motiv, Visual-Anker und Bild-Prompt aus der gewählten Satire-Variante, aufgerufen von P5 (ersetzt P5s alte "AI Visual JSON").
- `ALLRIS_Eignungs_Agent.json` — trifft die alleinige "braucht dieser Vorgang ein Sharepic?"-Entscheidung (siehe State-Management-Modell oben), aufgerufen von P3d.
- `ALLRIS_Lern_Agent.json` — speichert akzeptierte/abgelehnte QA-Beispiele und liefert sie als Few-Shot-Kontext zurück, damit neue Regeln nicht nur als zusätzliche Zeile in einem immer länger werdenden Prompt landen. Aufgerufen von P3d, rein additiv (fire-and-forget).
- `ALLRIS_Orchestrator_Shadow.json` — **einziger noch inaktiver Rest des alten Schattenbetriebs**, liest jede Zeile und berechnet unabhängig das Stage-Modell zur Gegenprobe; war das Werkzeug, mit dem die ursprüngliche Migration validiert wurde. Trotz des Namens keine echte Steuerungsinstanz: inaktiv, nur per Manual Trigger startbar, ruft keinen anderen Workflow auf. Die tatsächliche Pipeline-Steuerung passiert weiterhin implizit über die Zeitplan-Kaskade oben.
- `ALLRIS_*_AI_PROMPT_TO_PASTE.txt` — Prompt-Texte für die jeweiligen KI-Nodes der Agenten (müssen aktuell manuell über die n8n-Node-Palette ergänzt werden, siehe Hinweis unten).

## Hinweis zum Import

Diese Dateien sind n8n-Workflow-Exporte. Beim Import eines **neuen** Workflows mit einem LangChain/KI-Node (z.B. `ALLRIS_QA_Agent.json`) kann n8n mit `f[m] is not iterable` abbrechen — der KI-Node muss dann manuell über die "+"-Node-Palette ergänzt werden, statt über die Datei importiert zu werden.

Referenzierte Data-Table- und Workflow-IDs (z.B. `dataTableId`, `workflowId`) beziehen sich auf die private n8n-Instanz dieses Projekts und müssen nach einem Import in eine andere Instanz neu zugeordnet werden.

## Automatische Strukturprüfung

Die versionierte Workflow-ID-Landkarte liegt unter
[`docs/WORKFLOW_ID_MAP.md`](docs/WORKFLOW_ID_MAP.md). Exporte und optional die
Live-Instanz können mit PowerShell geprüft werden:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\Test-AllrisWorkflows.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\Test-AllrisWorkflows.ps1 -CheckLive
```

Die Live-Prüfung verwendet `N8N_API_KEY` und optional `N8N_BASE_URL`. Sie gibt
den Schlüssel nicht aus und prüft JSON-Struktur, Node-Verbindungen,
Sub-Workflow-IDs, Matrix-Authentifizierung und Abweichungen zwischen Git und
den gespeicherten Live-Workflows.
