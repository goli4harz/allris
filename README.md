# ALLRIS

n8n-Automatisierungspipeline für DIE PARTEI Kreisverband Goslar. Überwacht das Goslarer Ratsinformationssystem ALLRIS, bewertet neue Vorgänge, und generiert daraus automatisiert satirische Social-Media-Inhalte und Sharepics.

## Zusammenarbeit und Projektstatus

Die gemeinsame Kommunikations- und Übergabedatei für Oliver, Claude und Codex
ist [`PROJECT_COORDINATION.md`](PROJECT_COORDINATION.md). Dort werden
Anforderungen, offene Aufgaben, Entscheidungen, Blocker und Übergaben gepflegt.
Sie ist vor jeder Projektänderung zu lesen und bei relevanten Änderungen im
selben Commit zu aktualisieren.

## Produktions-Pipeline (P1–P7 + P3b/P3c/P3d)

Das sind die Dateien, die tatsächlich live laufen (n8n Schedule Trigger, alle 5 Stunden, zeitversetzt) und reale Vorgänge von der ALLRIS-Erfassung bis zur WordPress-Veröffentlichung durchreichen:

| Datei | Stufe | Warum diese Stufe eigenständig ist |
|---|---|---|
| `ALLRIS_P1_Ingestion.json` | Neue Vorgänge aus ALLRIS erfassen | Einziger Schreibzugriff auf die ALLRIS-Quelle; erkennt neue/geänderte Vorgänge und legt die Basiszeile in der Data Table an |
| `ALLRIS_P2_Nextcloud.json` | Dokumente herunterladen, in Nextcloud ablegen | Dokument-Download ist der langsamste/instabilste Schritt (externe PDFs) — getrennt von der Bewertung, damit ein Download-Fehler nicht die KI-Analyse blockiert |
| `ALLRIS_P3_Bewertung.json` | KI-Zusammenfassung + Relevanz-Analyse | Idempotenz-Guard, Folgevorgang-Kettenauflösung, Metadaten-Validierung, Summary-Beschaffung (inkl. Nextcloud/Tika-Fallback), KI-Analyse (Relevanz/"Sprengstoff"/Empfehlung). Endet an der bestehenden `contentStage`-Weiche (`needs_content`/`watching`/`ignored`) — bewusst schlank gehalten, seit 2026-07-19 (siehe unten) |
| `ALLRIS_P3b_Repair_SourceLock_VisualGuard.json` | Sub-Workflow: repariert unvollständige SourceLock/VisualAnchors | Kein eigener Trigger — wird von P3c aufgerufen, wenn eine Zeile unvollständige Daten hat, statt die teure P3-Analyse komplett zu wiederholen |
| `ALLRIS_P3c_Vorgangsabschluss.json` | Repair-Aufruf + Summary-Markdown/Nextcloud-Upload | Eigenständig seit 2026-07-19 (vorher Teil von P3): konsolidiert den Repair-Trigger und das Markdown-Archiv in einer schlanken, unabhängig testbaren Stufe |
| `ALLRIS_P3d_Agenten_Kette.json` | Eignungs-/Fakten-/QA-/Lern-/Satire-Agent-Kette | Eigenständig seit 2026-07-19 (vorher Teil von P3): die komplette KI-Urteils-Kette, die entscheidet ob/wie ein Sharepic-fähiges Thema vorliegt, extrahiert belegbare Fakten, prüft QA, und generiert Satire-Varianten inkl. Matrix-Umfrage |
| `ALLRIS_P4_Content_Reaktion.json` | Generiert Social-Media-Inhalte (Website, Facebook, Instagram, Reaktion) | Trennt Text-Content-Erzeugung von der Bewertung (P3), damit Content unabhängig nachbearbeitet/wiederholt werden kann |
| `ALLRIS_P5_Visual_Prompt_Builder.json` | Baut Bild-Prompt (Motiv, Headline-Varianten, Subline) | Eigene Stufe, weil die Headline-Auswahl einen menschlichen Zwischenschritt braucht (Matrix-Umfrage) — kann nicht in einem Durchlauf mit der Bildgenerierung stehen |
| `ALLRIS_P5b_Matrix_Headline_Reader.json` | Liest Matrix-Antworten auf Headline-Auswahl | Reply-Hälfte von P5s Umfrage; eigener 15-Minuten-Trigger, weil Matrix-Antworten asynchron zur 5-Stunden-Pipeline eintreffen |
| `ALLRIS_P6_Bildgenerierung.json` | Erzeugt und komponiert das Sharepic | Größte Datei: Bild-API-Aufruf, Compositing, Qualitätsprüfung, Nextcloud-Upload, Matrix-Post — bewusst als ein Block, da diese Schritte eng an denselben Bildzustand gekoppelt sind |
| `ALLRIS_P7_WordPress_Publish.json` | Veröffentlicht auf WordPress | Letzter, unumkehrbarer Schritt — eigene Stufe, damit ein WordPress-Fehler isoliert sichtbar bleibt und nicht mit Bildgenerierungsfehlern vermischt wird |

**Aktueller Stand (2026-07-19):** P3 wurde von 96 auf 54 Nodes verschlankt, indem zwei größtenteils unabhängige Verantwortlichkeiten (Repair+Archivierung, KI-Urteils-Kette) in die neuen Stufen `P3c_Vorgangsabschluss` und `P3d_Agenten_Kette` ausgelagert wurden — motiviert dadurch, dass P3 als Monolith zu unübersichtlich zum Debuggen wurde. Alle drei live getestet und schrittweise scharf geschaltet (Details siehe Git-Historie der jeweiligen Commits). Dabei zwei echte, vom Split unabhängige Bugs gefunden: die Spalte `eignungsAgentJson` existierte nie wirklich, wodurch der komplette Eignungs-Entscheidung-Schreibvorgang (inkl. `sharepicNeedStage`) seit dessen Einführung am Vortag silent fehlschlug; und ein Nextcloud-Upload-Node, dessen leerer Rückgabewert einen nachfolgenden DB-Schreibvorgang um seinen Row-Key brachte (gleiche Bugklasse wie ein früherer Matrix-Vorfall in P2). Zusätzlich wurde die n8n-Instanz aufgeräumt: 329 historische ALLRIS-Workflow-Versionsstände gelöscht (481→152 Workflows insgesamt) sowie 2 nie verdrahtete Data-Table-Spalten (`bildAgentJson`, `headlineChoiceProcessedAt`, 116→114 Spalten).

Vorherige Änderung (2026-07-18): mehrere Live-Bugs in P1 und P4 behoben (Content-Verlust nach dem Matrix-Post in P4, veraltete `visualStage`-Werte aus abgelösten Workflow-Versionen, dauerhaftes Alert-Spamming im "blockierte Vorgänge"-Dashboard, eine feste 2-Seiten-Grenze beim ALLRIS-Übersicht-Scraping in P1) sowie ein echter Zeitplan-Fehler in P7 (lief bisher *vor* P4 im selben 5-Stunden-Zyklus — behoben durch Verschieben von P7 ans Ende der Kaskade).

**Zeitplan-Kaskade (alle Stufen im selben 5h-Zyklus, zeitversetzt):** `P1=:05 → P2=:15 → P3=:25 → P3c=:28 → P3d=:32 → P4=:35 → P5=:45 → P6=:55 → P7=:58`. P3c/P3d laufen bewusst *vor* P4, da P4 `sharepicNeedStage` (von P3d geschrieben) und den Repair-Status (von P3c gepflegt) noch im selben Zyklus lesen muss — eine erste Version hatte P3d versehentlich auf :40 (nach P4) gelegt, was denselben Race-Fehler reproduziert hätte, der 2026-07-18 schon einmal bei P7-vs-P4 gefunden und behoben wurde; korrigiert vor dem Live-Gang. Rein zeitplanbasiert statt über Webhooks/direkte Aufrufe verkettet — das würde die Fehler-Isolation zwischen den Stufen aufgeben, für einen Latenzgewinn von nur wenigen Minuten pro Übergang.

## State-Management-Modell

Jede Zeile in der Data Table `allris_vorgaenge` trägt mehrere unabhängige Zustandsfelder, die den Fortschritt entlang orthogonaler Achsen beschreiben:

- **`contentStage`** (+ `contentErrorReason` bei Fehlern) — wie weit die Text-Content-Erzeugung ist (`needs_summary` → `content_generated` → `content_posted`, oder `error`)
- **`sharepicNeedStage`** — ob ein Sharepic für diesen Vorgang überhaupt sinnvoll/zulässig ist (`not_applicable` / `topic_ok` / `topic_error`), seit 2026-07-19 die alleinige, maßgebliche Entscheidung des `ALLRIS_Eignungs_Agent` (siehe unten) plus deterministischer SourceLock-/VisualAnchor-/Guard-Prüfung danach, die nur noch *verschärfen*, nie überstimmen kann
- **`headlineChoiceStage`** — wie weit die Matrix-Umfrage zur Headline-/Satire-Varianten-Auswahl ist (`awaiting_headline_choice` → `headline_selected`, oder `satire_agent_failed`)
- **`visualPromptStage`** — wie weit der Bild-Prompt-Bau ist (`needs_prompt` → `prompt_ready`, oder `prompt_error`), von P4→P5→P6 gemeinsam gepflegt
- **`imageStage`** — wie weit die eigentliche Bildgenerierung ist (`not_started` → `qa_pending` → `composed` …)

Das ersetzt zwei ältere Modelle: zuerst ein zwei-Felder-Modell (`status`, `visualStatus`), das de facto drei Zustände in zwei Spalten kodierte und wiederholt zu Bugs führte (Migration 2026-07-17/18); danach ein einzelnes `visualStage`-Feld, das von **drei unabhängig entstandenen, teils widersprüchlichen Formeln** parallel beschrieben wurde (P3 direkt nach der Analyse, P3 nach der Headline-Umfrage, P4 nach der Content-Erzeugung — mit jeweils eigenen, leicht unterschiedlichen Schwellenwerten auf denselben Zahlen). **Am 2026-07-19 aufgelöst**: der neue `ALLRIS_Eignungs_Agent` trifft die "braucht dieser Vorgang ein Sharepic?"-Entscheidung als echtes redaktionelles Ermessen (KI-Agent, kein Schwellenwert), `visualStage` wurde in die drei oben genannten, klar getrennten Felder aufgeteilt. Ein manuelles Force-Reset läuft weiterhin über zwei eigene Boolean-Spalten (`visualForceReset`, `imageForceReset`) statt über magische String-Werte.

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
