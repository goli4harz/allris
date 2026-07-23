# ALLRIS – Workflow-ID-Landkarte

Stand: 2026-07-23

Diese Datei ordnet die versionierten Workflow-Exporte den produktiven n8n-IDs
zu. IDs sind instanzspezifisch. Nach einem Import in eine andere n8n-Instanz
müssen sowohl diese Landkarte als auch alle `Execute Workflow`-Nodes angepasst
werden.

| Export | Live-ID | Rolle | Live aktiv |
|---|---|---|---|
| `ALLRIS_P1_Ingestion.json` | `9YDd8kZJxcoX3aDg` | ALLRIS-Erfassung | ja |
| `ALLRIS_P2_Nextcloud.json` | `Bg1wSuj202RnkrLB` | Nextcloud-Archivierung | ja |
| `ALLRIS_P3_Bewertung.json` | `cAjWIjnZ8BCt3dFX` | Zusammenfassung und Bewertung | ja |
| `ALLRIS_P3b_Repair_SourceLock_VisualGuard.json` | `KfPtfJfOe39LTJzR` | Repair-Sub-Workflow | ja |
| `ALLRIS_P3c_Vorgangsabschluss.json` | `8Nxv36hBfO8lYW83` | Repair und Summary-Archiv | ja |
| `ALLRIS_P3d_Agenten_Kette.json` | `a3PHW4QilKpzA082` | Eignung, Fakten, QA und Lernen | ja |
| `ALLRIS_P3e_Kernbotschaft.json` | `qyzpgoD4bfTI2ncf` | Satire und Kernbotschaft | ja |
| `ALLRIS_P4_Content_Reaktion.json` | `wGLMrDnSavNIprzu` | Content-Erzeugung | ja |
| `ALLRIS_P5_Visual_Prompt_Builder.json` | `WIg40QYXmouRoYjq` | Visual-Prompt | ja |
| `ALLRIS_P5b_Matrix_Headline_Reader.json` | `4VXIOwv6ouMbBCER` | Matrix-Auswahl | ja |
| `ALLRIS_P6_Bildgenerierung.json` | `LZKgUF2ad5qDXdB0` | Bildgenerierung | ja |
| `ALLRIS_P7_WordPress_Publish.json` | `4GRt1nt9KYJaCAWF` | WordPress golietz.de | ja |
| `ALLRIS_P8_Partei_Webseite.json` | `3pAntGoWcG2uAig4` | WordPress Partei-Webseite | ja |
| `ALLRIS_Paperless_Backfill.json` | `UYCdv5g37YbNBKLh` | Paperless-Backfill | ja |
| `ALLRIS_Status_Uebersicht.json` | `yI8lClVAuj6aS5Lz` | LAN-Statusübersicht | ja |
| `ALLRIS_Dispatcher_Watchdog.json` | `UzevGR7GafUB3dFk` | Watchdog und manueller Claim-Test | nein |
| `ALLRIS_Eignungs_Agent.json` | `ZZeD2dqzJUdCCksQ` | Eignungs-Agent | ja |
| `ALLRIS_Fakten_Agent.json` | `6t3TBZtYtKgElV0d` | Fakten-Agent | ja |
| `ALLRIS_QA_Agent.json` | `zJjry37DnhDVErfC` | QA-Agent | ja |
| `ALLRIS_Lern_Agent.json` | `Br1O0rUucRnLdKvi` | Lern-Agent | ja |
| `ALLRIS_Satire_Agent.json` | `NO17q38BeKyS25LY` | Satire-Agent | ja |
| `ALLRIS_Bild_Agent.json` | `WR1xVNo4AjcsKlMv` | Bild-Agent | ja |

## Nur versioniert, nicht live vorhanden

- `ALLRIS_Orchestrator_Shadow.json`
- `ALLRIS_Reset_Paperless_Backfill_Marker.json`

## Data Tables

| Tabelle | Live-ID | Projekt-ID | Rolle |
|---|---|---|---|
| `allris_vorgaenge` | `hBLqpqeVEojPpOJl` | `CrnegVcMvlcRU0OP` | Aktueller Zustand je Vorgang |
| `allris_state_history` | `Q54kptpOrbug6bJu` | `CrnegVcMvlcRU0OP` | Append-only Zustands- und Fehlerhistorie |

`allris_state_history` wurde am 2026-07-23 vollständig gemäß
`PAKET2_DB_SPEZIFIKATION.md` angelegt. Die sechs additiven Fehlerfelder auf
`allris_vorgaenge` fehlen noch, weil die öffentliche API dieser n8n-Version
keine Spaltenänderungen an bestehenden Tabellen anbietet.

## Verbindliche Sub-Workflow-Aufrufe

| Aufrufer | Ziel | Live-ID |
|---|---|---|
| P3c | Repair SourceLock/VisualGuard | `KfPtfJfOe39LTJzR` |
| P3d | Eignungs-Agent | `ZZeD2dqzJUdCCksQ` |
| P3d | Fakten-Agent | `6t3TBZtYtKgElV0d` |
| P3d | QA-Agent | `zJjry37DnhDVErfC` |
| P3d | Lern-Agent | `Br1O0rUucRnLdKvi` |
| P3e | Satire-Agent | `NO17q38BeKyS25LY` |
| P5 | Bild-Agent | `WR1xVNo4AjcsKlMv` |

## Bewusst akzeptierte Live-Abweichung

`ALLRIS_Status_Uebersicht` läuft ausschließlich im LAN. Oliver hat am
2026-07-23 bestätigt, dass der Live-Betrieb ohne das im Export enthaltene
Token-Gate akzeptiert ist. Der Drift-Test meldet diese Abweichung deshalb als
Warnung, nicht als Fehler.
