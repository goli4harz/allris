# RatsPilot

## Was ist das – und was bringt es mir?

**Kurz gesagt:** RatsPilot beobachtet automatisch das Goslarer Ratsinformationssystem (ALLRIS) und macht aus neuen politischen Vorgängen – Anträgen, Anfragen, Mitteilungen der Verwaltung – automatisch fertige, satirische Social-Media-Beiträge samt passendem Bild. Ohne dass jemand manuell Ratsdokumente durchforsten oder Beiträge von Hand schreiben muss.

*Namensklärung: „RatsPilot" ist der Name dieser Software. „ALLRIS" ist das Ratsinformationssystem der Stadt Goslar, das RatsPilot beobachtet – ein fremdes System, keine eigene Komponente. Im technischen Teil unten taucht „ALLRIS" deshalb noch häufig in Datei- und Workflownamen auf, weil das Projekt historisch nach diesem beobachteten System benannt war.*

Diese Dokumentation richtet sich zunächst an Sie als kommunalpolitisch Aktive, die wissen wollen, was RatsPilot bringt – nicht an Techniker. Der technische Teil weiter unten ist für die Wartung gedacht und kann übersprungen werden.

### Was das konkret für Sie bedeutet

- **Sie verpassen nichts mehr.** Jeder neue Vorgang im Ratsinformationssystem wird automatisch erkannt – auch dann, wenn gerade niemand Zeit hatte, selbst nachzuschauen.
- **Kein manuelles Wälzen von Sitzungsunterlagen.** RatsPilot liest die oft langen, sperrigen Verwaltungsdokumente, fasst sie zusammen und bewertet, ob ein Vorgang politisch relevant und öffentlichkeitswirksam ist.
- **Fertige Social-Media-Beiträge, ohne dass jemand am Schreibtisch sitzen muss.** Website-Artikel sowie Facebook-, Instagram- und Mastodon-Beiträge werden inklusive Bild automatisch erstellt und veröffentlicht – im typischen, satirischen Ton der PARTEI.
- **Kontinuierliche Präsenz ohne Mehraufwand.** Statt „wir posten, wenn mal wieder wer Zeit findet" gibt es einen verlässlichen, mehrmals täglich laufenden Automatismus.
- **Der Mensch bleibt an den wichtigen Stellen im Boot.** Bei der Auswahl der besten Schlagzeile für ein Sharepic wird kurz per Chat-Umfrage nachgefragt – kein Beitrag geht ganz ohne redaktionelle Kontrolle raus.
- **Mehr Zeit für echte politische Arbeit.** Der Zeitaufwand, der sonst für Social-Media-Redaktion draufgeht, entfällt weitgehend.

### Wie das grob funktioniert (ohne Technik-Details)

1. RatsPilot schaut regelmäßig ins Ratsinformationssystem und merkt sich neue Vorgänge.
2. Zugehörige Dokumente werden automatisch geladen und ausgewertet.
3. Eine KI entscheidet, ob ein Vorgang interessant genug für eine öffentliche Reaktion ist.
4. Für relevante Vorgänge werden automatisch Texte für Website, Facebook, Instagram und Mastodon geschrieben.
5. Falls ein Bild (Sharepic) sinnvoll ist, wird passendes Bildmaterial automatisch erzeugt – die beste Schlagzeile dafür wird kurz per Chat abgefragt.
6. Alles wird zeitversetzt und automatisch veröffentlicht.

Für alles Weitere – wie das im Detail technisch aufgebaut ist – richtet sich der Rest dieser Dokumentation an Personen, die das System warten oder weiterentwickeln.

## Technische Dokumentation

n8n-Automatisierungspipeline für DIE PARTEI Kreisverband Goslar. Überwacht das Goslarer Ratsinformationssystem ALLRIS, bewertet neue Vorgänge, und generiert daraus automatisiert satirische Social-Media-Inhalte und Sharepics.

## Produktions-Pipeline (P1–P11 + P3b/P3c/P3d/P3e + P8b)

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
| `ALLRIS_P10_Instagram_Publish.json` | Veröffentlicht auf Instagram | **Aktiv** (Stand 2026-09-01, live verifiziert) — 26 Nodes, gleiches Claim-/History-Muster wie P9, Graph-API Media-Container→Publish-Flow, nutzt dieselbe P8-Bild-URL |
| `ALLRIS_P11_Facebook_Publish.json` | Veröffentlicht auf Facebook | **Aktiv** (Stand 2026-09-01, live verifiziert), claim-gated wie die übrigen Publish-Stufen |

**Zeitplan-Kaskade** (P1/P2 alle 5h, P3–P8 stündlich, P9–P11 mehrfach täglich zu festen Uhrzeiten, P8b täglich): `P1=:05(5h) → P2=:15(5h) → P3=:05 → P3d=:13 → P4=:21 → P3c=:40 → P5=:29 → P3e=:33 → P6=:37 → P7=:45 → P8=:52` und separat `Paperless-Backfill=:00(1h)`, `P8b=täglich 07:30+17:00`, `P9=stündlich 8–17 Uhr`, `P10=2-stündlich 7–19 Uhr`, `P11=stündlich 7–21 Uhr` (Stand 2026-09-01, live verifiziert — die Publish-Frequenzen wurden mit Blick auf die Kommunalwahl am 13.09. erhöht, siehe Wahlkampf-Taktung). P3c wurde am 2026-09-01 von `:28` auf `:40` verschoben, weil P4 real bis zu ~6 Min. laufen kann und beide denselben `contentStage=needs_content`-Filter lesen — der ursprüngliche Abstand von 7 Min. ließ im Worst Case nur ~12s Puffer. Atomare Claim-/Lease-Sperren verhindern in P2, P3, P3c, P3d, P3e, P4–P8, **P8b, P9, P10, P11** sowie im Paperless-Backfill, dass parallele Läufe denselben Vorgang gleichzeitig bearbeiten. Ein Claim ersetzt keine fachliche Eingangsvoraussetzung und garantiert nicht den Abschluss der vorherigen Stufe.

## Hilfs- und Betriebsworkflows

- `ALLRIS_Paperless_Backfill.json` läuft stündlich zur Minute `:00` (live
  verifiziert 2026-07-26) und überträgt archivierte Originaldokumente nach Paperless.
- `ALLRIS_P4b_Metadaten_Nachzieher.json` läuft alle 3 Stunden zur Minute `:50`
  und trägt Metadaten (u.a. `vorlageDatum`) nach, die beim ersten P4-Lauf noch fehlten.
- `ALLRIS_Status_Uebersicht.json` stellt die im LAN verwendete
  Statusübersicht bereit (Webhook-getriggert, kein eigener Schedule).
- `ALLRIS_Web_NavBar.json` liefert die gemeinsame Navigationsleiste für die
  internen Web-Seiten (Status_Uebersicht u.a.), ebenfalls ohne eigenen Schedule.
- `ALLRIS_Claim_Error_Release.json` ist der zentrale n8n-`errorWorkflow` für
  P4, P8b, P9, P10 und P11 (in `settings.errorWorkflow` eingetragen, kein
  expliziter Execute-Workflow-Aufruf nötig) — gibt bei einem Absturz
  automatisch den Claim des betroffenen Vorgangs wieder frei.
- `ALLRIS_Wahlkampf_Bildgenerator.json` ist ein separates, aktives Werkzeug
  für Wahlkampf-Sharepics außerhalb der regulären Vorgangs-Pipeline.
- `ALLRIS_Dispatcher_Watchdog.json` und `ALLRIS_Watchdog_P10_P11_Trigger.json`
  sind inaktiv (`ALLRIS_Dispatcher_Watchdog.json` zusätzlich archiviert) und
  steuern die Pipeline nicht; sie dienten kontrollierten Claim-/Lease- bzw.
  Publish-Trigger-Tests.
- `ALLRIS_Nextcloud_Backup_OMV.json` ist inaktiv und **nicht produktionsbereit**
  — fertiges Zeitplan-/Backup-Gerüst, aber ohne SSH-Credential und mit
  Platzhalter-Pfaden. Offene Werte in
  [`docs/NEXTCLOUD_BACKUP_TODO.md`](docs/NEXTCLOUD_BACKUP_TODO.md).
- `ALLRIS_Claim_Lease.json` ist der veröffentlichte, triggerlose Sub-Workflow
  für atomaren Claim-Erwerb, Re-Read und owner-gebundene Freigabe. Die
  Stufen P2, P3, P3c, P3d, P3e, P4–P8, **P8b, P9, P10 und P11** sowie der
  Paperless-Backfill verwenden ihn; er kann nicht selbstständig starten.
Erledigte, einmalig genutzte Reparatur- und Diagnose-Workflows (Manual Trigger, inaktiv) liegen
gesammelt in [`archive/einmalig-diagnose/`](archive/einmalig-diagnose/) — dazu zählen u.a. der
alte Vergleichsworkflow `ALLRIS_Orchestrator_Shadow.json`, `ALLRIS_Reset_Paperless_Backfill_Marker.json`
sowie sämtliche `ALLRIS_Einmalig_*`/`ALLRIS_Diagnose_*`-Dateien. Sie bleiben aus der Historie heraus
abrufbar, sind aber keine aktiven Bestandteile der Pipeline mehr.

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
- `ALLRIS_Orchestrator_Shadow.json` — war das Werkzeug, mit dem die ursprüngliche Migration validiert wurde. **Existiert nicht mehr in der Live-Instanz** (vermutlich im Rahmen einer Instanz-Bereinigung entfernt); die lokale Datei liegt archiviert in [`archive/einmalig-diagnose/`](archive/einmalig-diagnose/). War ohnehin nie eine echte Steuerungsinstanz: nur per Manual Trigger startbar, rief keinen anderen Workflow auf. Die tatsächliche Pipeline-Steuerung passiert weiterhin implizit über die Zeitplan-Kaskade oben.
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
