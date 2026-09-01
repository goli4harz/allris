# Nextcloud-Backup (`ALLRIS_Nextcloud_Backup_OMV`) — offener TODO

Stand 2026-09-01 (RatsPilot-Audit, live und lokal gegengeprüft): dieser Workflow ist ein
fertiges Gerüst, aber **nicht produktionsbereit**. Er ist bewusst `active: false` und darf
nicht ohne die unten genannten Werte aktiviert werden.

## Was schon fertig ist

- Zeitplan: wöchentlich, Sonntag 03:00 Uhr — bereits real konfiguriert, kein Platzhalter.
- Backup-Logik im SSH-Command (`rsync` mit Hardlink-Delta gegen den letzten Stand, Retention,
  `latest`-Symlink) ist inhaltlich fertig geschrieben, nicht nur skizziert.
- `RETENTION_COUNT=6` (wöchentliche Backups, laut Kommentar "4-8 laut Absprache") ist ein
  echter, gesetzter Wert — kein Platzhalter.
- Ergebnisprüfung (`Prüfe Ergebnis`-Node) wertet `stdout`/`stderr`/Exit-Code aus.

## Was fehlt, bevor der Workflow aktiviert werden kann

1. **SSH-Credential für den Nextcloud-Host.** Der SSH-Node (`Fuehre Backup aus (SSH)`) hat
   aktuell **gar keine Credential zugewiesen** (kein `credentials`-Objekt im Node). Muss manuell
   in der n8n-UI angelegt und im Node ausgewählt werden — das kann nicht per API gesetzt werden.
2. **`SRC` im SSH-Command** (aktuell Platzhalter `__NEXTCLOUD_DATA_PATH__`): der tatsächliche
   Pfad zu den Nextcloud-Nutzdaten auf dem Zielserver (z.B. `/var/www/nextcloud/data` oder ein
   Docker-Volume-Pfad — hängt davon ab, wie Nextcloud dort installiert ist).
3. **`DEST_BASE` im SSH-Command** (aktuell Platzhalter `__OMV_MOUNT_PATH__`): der lokal auf dem
   Nextcloud-Host gemountete OMV-Freigabepfad, auf den die Backups geschrieben werden sollen
   (z.B. `/mnt/omv-backup/nextcloud`). Setzt voraus, dass dieser Mount auf dem Host bereits
   eingerichtet ist.

## Was absichtlich nicht geraten wurde

Keiner der drei fehlenden Werte ließ sich aus vorhandenen Projektdateien ableiten (anders als
z.B. Data-Table-IDs oder Workflow-IDs, die im Repo eindeutig belegt sind) — SSH-Zugangsdaten und
Server-interne Pfade sind nicht Teil des Repos und müssen vom Nutzer kommen.

## Zusätzlich zu bedenken (kein Blocker, aber noch nicht vorhanden)

Der Workflow meldet ein fehlgeschlagenes Backup aktuell nur per `console.error` im
Node-Log — es gibt (anders als bei den übrigen Fehlerpfaden der Pipeline) **keine
Matrix-Benachrichtigung und keinen Eintrag in `allris_state_history`** bei einem
fehlgeschlagenen Lauf. Bei einem wöchentlichen Backup, das niemand aktiv beobachtet, würde ein
stiller Fehler sonst erst auffallen, wenn ein Restore gebraucht wird. Sollte ergänzt werden,
sobald der Workflow aktiviert wird — nicht Teil dieser Dokumentation, nur als Merkposten.
