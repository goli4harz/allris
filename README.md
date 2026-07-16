# ALLRIS

n8n-Automatisierungspipeline für DIE PARTEI Kreisverband Goslar. Überwacht das Goslarer Ratsinformationssystem ALLRIS, bewertet neue Vorgänge, und generiert daraus automatisiert satirische Social-Media-Inhalte und Sharepics.

## Pipeline-Stufen

| Datei | Stufe |
|---|---|
| `ALLRIS_P1_Ingestion.json` | Neue Vorgänge aus ALLRIS erfassen |
| `ALLRIS_P2_Nextcloud.json` | Dokumente herunterladen, in Nextcloud ablegen |
| `ALLRIS_P3_Bewertung.json` | KI-Zusammenfassung + Relevanz-/Satire-Analyse |
| `ALLRIS_P3b_Repair_SourceLock_VisualGuard.json` | Sub-Workflow: repariert unvollständige SourceLock/VisualAnchors |
| `ALLRIS_P4_Content_Reaktion.json` | Generiert Social-Media-Inhalte (Website, Facebook, Instagram, Reaktion) |
| `ALLRIS_P5_Visual_Prompt_Builder.json` | Baut Bild-Prompt (Motiv, Headline, Subline) |
| `ALLRIS_P5b_Matrix_Headline_Reader.json` | Liest Matrix-Antworten auf Headline-Auswahl |
| `ALLRIS_P6_Bildgenerierung.json` | Erzeugt und komponiert das Sharepic |
| `ALLRIS_P7_WordPress_Publish.json` | Veröffentlicht auf WordPress |

## Multi-Agenten-Architektur (im Aufbau)

Zusätzlich zur klassischen Pipeline entsteht schrittweise ein System aus sechs einzeln zuständigen Agenten (Fakten, Analyse, Satire, Bild, QA, Lern) plus Orchestrator, das die verstreute Validierungslogik konsolidiert. Alle Agenten laufen aktuell im **Schattenbetrieb** neben der klassischen Pipeline (P1–P7) — sie schreiben in eigene Spalten, ohne bestehendes Verhalten zu verändern:

- `ALLRIS_QA_Agent.json` — konsolidierter Prüf-Agent (SourceLock/VisualAnchors-Vollständigkeit, Halluzinationsprüfung).
- `ALLRIS_Lern_Agent.json` — speichert akzeptierte/abgelehnte QA-Beispiele und liefert sie als Few-Shot-Kontext zurück.
- `ALLRIS_Fakten_Agent.json` — reine Fakten-Extraktion (keine Interpretation), Grundlage für Satire- und Bild-Agent.
- `ALLRIS_Satire_Agent.json` — generiert mehrere Satire-Varianten in unterschiedlicher Schärfe inkl. Headline/Subline, auf Basis der extrahierten Fakten.
- `ALLRIS_Bild_Agent.json` — baut Bild-Motiv, Visual-Anker und Bild-Prompt aus einer gewählten Satire-Variante.
- `ALLRIS_*_AI_PROMPT_TO_PASTE.txt` — Prompt-Texte für die jeweiligen KI-Nodes (müssen manuell über die n8n-Node-Palette ergänzt werden, siehe Hinweis unten).

### Orchestrator (Phase 6, im Aufbau)

Ziel: die inzwischen ~45+ verstreuten `status`/`visualStatus`-Werte durch drei zentral definierte Achsen ersetzen (`contentStage`, `visualStage`, `imageStage`).

- `ALLRIS_Orchestrator_Shadow.json` — liest alle Zeilen und berechnet unabhängig, was die drei neuen Achsen jeweils sein sollten (reiner Beobachter, schreibt nur in neue Spalten).
- **Durchgang A (additives Dual-Write) ist abgeschlossen:** alle 9 Pipeline-Dateien (P1, P7, P2, P3, P3b, P4, P5, P5b, P6) schreiben die neuen Felder inzwischen selbst mit, parallel zu `status`/`visualStatus` — ohne bestehendes Verhalten zu ändern. Bisher ist nur P1 live in n8n getestet, die übrigen 8 sind code-geprüft, aber noch nicht importiert.
- **Durchgang B (Lesen auf die neuen Felder umstellen)** ist noch nicht begonnen.

## Hinweis zum Import

Diese Dateien sind n8n-Workflow-Exporte. Beim Import eines **neuen** Workflows mit einem LangChain/KI-Node (z.B. `ALLRIS_QA_Agent.json`) kann n8n mit `f[m] is not iterable` abbrechen — der KI-Node muss dann manuell über die "+"-Node-Palette ergänzt werden, statt über die Datei importiert zu werden.

Referenzierte Data-Table- und Workflow-IDs (z.B. `dataTableId`, `workflowId`) beziehen sich auf die private n8n-Instanz dieses Projekts und müssen nach einem Import in eine andere Instanz neu zugeordnet werden.
