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

Zusätzlich zur klassischen Pipeline entsteht schrittweise ein System aus sechs einzeln zuständigen Agenten (Fakten, Analyse, Satire, Bild, QA, Lern) plus Orchestrator, das die verstreute Validierungslogik konsolidiert:

- `ALLRIS_QA_Agent.json` — konsolidierter Prüf-Agent (SourceLock/VisualAnchors-Vollständigkeit, Halluzinationsprüfung), aktuell im Schattenbetrieb neben P3.
- `ALLRIS_Lern_Agent.json` — speichert akzeptierte/abgelehnte QA-Beispiele und liefert sie als Few-Shot-Kontext zurück.
- `ALLRIS_QA_Agent_AI_PROMPT_TO_PASTE.txt` — Prompt-Text für den KI-Node im QA-Agenten (muss manuell über die n8n-Node-Palette ergänzt werden, siehe Hinweis unten).

## Hinweis zum Import

Diese Dateien sind n8n-Workflow-Exporte. Beim Import eines **neuen** Workflows mit einem LangChain/KI-Node (z.B. `ALLRIS_QA_Agent.json`) kann n8n mit `f[m] is not iterable` abbrechen — der KI-Node muss dann manuell über die "+"-Node-Palette ergänzt werden, statt über die Datei importiert zu werden.

Referenzierte Data-Table- und Workflow-IDs (z.B. `dataTableId`, `workflowId`) beziehen sich auf die private n8n-Instanz dieses Projekts und müssen nach einem Import in eine andere Instanz neu zugeordnet werden.
