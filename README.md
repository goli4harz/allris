# ALLRIS

n8n-Automatisierungspipeline für DIE PARTEI Kreisverband Goslar. Überwacht das Goslarer Ratsinformationssystem ALLRIS, bewertet neue Vorgänge, und generiert daraus automatisiert satirische Social-Media-Inhalte und Sharepics.

## Produktions-Pipeline (P1–P7)

Das sind die 9 Dateien, die tatsächlich live laufen (n8n Schedule Trigger, alle 5 Stunden, zeitversetzt) und die reale Vorgänge von der ALLRIS-Erfassung bis zur WordPress-Veröffentlichung durchreichen:

| Datei | Stufe | Warum diese Stufe eigenständig ist |
|---|---|---|
| `ALLRIS_P1_Ingestion.json` | Neue Vorgänge aus ALLRIS erfassen | Einziger Schreibzugriff auf die ALLRIS-Quelle; erkennt neue/geänderte Vorgänge und legt die Basiszeile in der Data Table an |
| `ALLRIS_P2_Nextcloud.json` | Dokumente herunterladen, in Nextcloud ablegen | Dokument-Download ist der langsamste/instabilste Schritt (externe PDFs) — getrennt von der Bewertung, damit ein Download-Fehler nicht die KI-Analyse blockiert |
| `ALLRIS_P3_Bewertung.json` | KI-Zusammenfassung + Relevanz-/Satire-Analyse | Größte/teuerste KI-Stufe (77 Nodes); bewertet Relevanz, "Sprengstoff", erzeugt Satire-Briefing und SourceLock (faktischer Anker gegen Halluzination) |
| `ALLRIS_P3b_Repair_SourceLock_VisualGuard.json` | Sub-Workflow: repariert unvollständige SourceLock/VisualAnchors | Kein eigener Trigger — wird von anderen Workflows aufgerufen, wenn P3s Output unvollständig war, statt die teure P3-Analyse komplett zu wiederholen |
| `ALLRIS_P4_Content_Reaktion.json` | Generiert Social-Media-Inhalte (Website, Facebook, Instagram, Reaktion) | Trennt Text-Content-Erzeugung von der Bewertung (P3), damit Content unabhängig nachbearbeitet/wiederholt werden kann |
| `ALLRIS_P5_Visual_Prompt_Builder.json` | Baut Bild-Prompt (Motiv, Headline-Varianten, Subline) | Eigene Stufe, weil die Headline-Auswahl einen menschlichen Zwischenschritt braucht (Matrix-Umfrage) — kann nicht in einem Durchlauf mit der Bildgenerierung stehen |
| `ALLRIS_P5b_Matrix_Headline_Reader.json` | Liest Matrix-Antworten auf Headline-Auswahl | Reply-Hälfte von P5s Umfrage; eigener 15-Minuten-Trigger, weil Matrix-Antworten asynchron zur 5-Stunden-Pipeline eintreffen |
| `ALLRIS_P6_Bildgenerierung.json` | Erzeugt und komponiert das Sharepic | Größte Datei (49 Nodes, ~470KB): Bild-API-Aufruf, Compositing, Qualitätsprüfung, Nextcloud-Upload, Matrix-Post — bewusst als ein Block, da diese Schritte eng an denselben Bildzustand gekoppelt sind |
| `ALLRIS_P7_WordPress_Publish.json` | Veröffentlicht auf WordPress | Letzter, unumkehrbarer Schritt — eigene Stufe, damit ein WordPress-Fehler isoliert sichtbar bleibt und nicht mit Bildgenerierungsfehlern vermischt wird |

**Aktueller Stand (2026-07-17):** Alle 9 Dateien wurden vollständig auf das neue Stage-Modell (siehe unten) umgestellt, leben produktiv in n8n und sind auf GitHub gesichert. P3 und P6 wurden nach der Umstellung live im n8n-UI nachgetestet und bestanden (dabei wurden 2 weitere Bugs gefunden und behoben). Ausstehend: Leerung der `allris_vorgaenge`-Tabelle und ein frischer Voll-Durchlauf, sobald Nextcloud/WordPress bestätigt leer sind.

## State-Management-Modell

Jede Zeile in der Data Table `allris_vorgaenge` trägt drei unabhängige Zustandsfelder, die den Fortschritt entlang drei orthogonaler Achsen beschreiben:

- **`contentStage`** (+ `contentErrorReason` bei Fehlern) — wie weit die Text-Content-Erzeugung ist (`needs_summary` → `content_generated` → `content_posted`, oder `error`)
- **`visualStage`** — wie weit die Bild-Prompt-/Headline-Auswahl ist (`not_applicable` → `needs_prompt` → `awaiting_headline_choice` → `prompt_ready` …)
- **`imageStage`** — wie weit die eigentliche Bildgenerierung ist (`not_started` → `qa_pending` → `composed` …)

Das ersetzt ein älteres Modell mit nur zwei Feldern (`status`, `visualStatus`), die de facto drei Zustände in zwei Spalten kodierten und dadurch wiederholt zu Bugs führten (ein Reparatur-Node setzte eine Spalte zurück, ohne zu prüfen, ob eine *andere* Achse längst weiter war). `status`/`visualStatus` wurden am 2026-07-17 vollständig aus allen 9 Dateien entfernt — keine Datei liest oder schreibt sie noch für Kontrollfluss-Entscheidungen. Ein manuelles Force-Reset läuft seither über zwei eigene Boolean-Spalten (`visualForceReset`, `imageForceReset`) statt über magische String-Werte.

## Multi-Agenten-System (Schattenbetrieb, noch nicht produktiv)

Parallel zur Pipeline oben entsteht ein zweites System aus sechs einzeln zuständigen Agenten plus Orchestrator — **kein Ersatz der laufenden Pipeline, sondern ein noch laufendes Forschungs-/Vergleichs-Gleis daneben.** Grund für den Parallelbetrieb: die Validierungs- und Generierungslogik der klassischen Pipeline ist über Jahre über P3/P3b/P4/P5 verstreut (5 verschiedene, teils unterschiedlich vollständige Implementierungen derselben Prüfungen). Die Agenten konsolidieren das schrittweise zu einer einzigen Implementierung je Zuständigkeit, werden aber erst produktiv geschaltet, wenn ihre Qualität im direkten Vergleich mit der laufenden Pipeline geprüft ist.

Alle sechs Phasen sind gebaut und im Schattenbetrieb verifiziert: sie laufen bei jedem P3-Durchlauf zusätzlich mit, schreiben in eigene, separate Spalten (`qaVerdictJson`, `faktenAgentJson`, `satireAgentJson`, `bildAgentJson`, …) und verändern nichts an dem, was tatsächlich veröffentlicht wird.

- `ALLRIS_QA_Agent.json` — konsolidierter Prüf-Agent (SourceLock/VisualAnchors-Vollständigkeit, Halluzinationsprüfung). Fasst 5 vorher verstreute Prüf-Implementierungen zusammen.
- `ALLRIS_Lern_Agent.json` — speichert akzeptierte/abgelehnte QA-Beispiele und liefert sie als Few-Shot-Kontext zurück, damit neue Regeln nicht mehr nur als zusätzliche Zeile in einem immer länger werdenden Prompt landen.
- `ALLRIS_Fakten_Agent.json` — reine Fakten-Extraktion ohne Interpretation, Grundlage für Satire- und Bild-Agent (trennt Fakten von Bewertung, die P3 aktuell noch in einem Schritt vermischt).
- `ALLRIS_Satire_Agent.json` — generiert mehrere Satire-Varianten in unterschiedlicher Schärfe inkl. Headline/Subline, ausschließlich auf Basis der extrahierten Fakten (nicht der freien Interpretation).
- `ALLRIS_Bild_Agent.json` — baut Bild-Motiv, Visual-Anker und Bild-Prompt aus einer gewählten Satire-Variante; fasst zusammen, was heute zwischen P3 (Anker) und P5 (Prompt) aufgeteilt ist.
- `ALLRIS_Orchestrator_Shadow.json` — liest jede Zeile und berechnet unabhängig das dreiachsige Stage-Modell zur Gegenprobe; war das Werkzeug, mit dem die Migration oben validiert wurde, bevor sie live geschaltet wurde.
- `ALLRIS_*_AI_PROMPT_TO_PASTE.txt` — Prompt-Texte für die jeweiligen KI-Nodes der Agenten (müssen aktuell manuell über die n8n-Node-Palette ergänzt werden, siehe Hinweis unten).

**Warum diese Dateien nicht einfach gelöscht oder mit der Pipeline zusammengeführt werden:** sie sind der geplante nächste Entwicklungsschritt, kein Altlast-Code. Ein zukünftiger Cutover würde P3/P4/P5 schrittweise durch Aufrufe dieser Agenten ersetzen, sobald genug Vergleichsdaten vorliegen.

## Hinweis zum Import

Diese Dateien sind n8n-Workflow-Exporte. Beim Import eines **neuen** Workflows mit einem LangChain/KI-Node (z.B. `ALLRIS_QA_Agent.json`) kann n8n mit `f[m] is not iterable` abbrechen — der KI-Node muss dann manuell über die "+"-Node-Palette ergänzt werden, statt über die Datei importiert zu werden.

Referenzierte Data-Table- und Workflow-IDs (z.B. `dataTableId`, `workflowId`) beziehen sich auf die private n8n-Instanz dieses Projekts und müssen nach einem Import in eine andere Instanz neu zugeordnet werden.
