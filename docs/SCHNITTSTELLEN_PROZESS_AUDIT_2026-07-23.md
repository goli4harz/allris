# ALLRIS – Schnittstellen- und Prozessaudit

**Datum:** 2026-07-23  
**Prüfart:** statische Prüfung der versionierten n8n-Exporte  
**Geprüfter Stand:** Commit `7b0eeea`

## 1. Ergebnis

Die Pipeline ist fachlich weit entwickelt, ihre Teilprozesse sind aber nicht
durch einen gemeinsamen, technisch erzwungenen Prozessvertrag gekoppelt.
Bestätigt wurden zwei besonders dringende und mehrere hohe Risiken:

1. P6 sendet den finalen Presseartikel an Matrix ohne aktivierte
   HTTP-Authentifizierung.
2. P7 veröffentlicht mit einem zu breiten Kandidaten-Gate unmittelbar als
   `publish`.
3. `sourceConflict` ist in vorgelagerten Prüfungen optional, in P6 jedoch
   zwingend erforderlich.
4. Die zeitbasierte Kaskade garantiert weder Abschlussreihenfolge noch
   Exklusivität.
5. Fehler werden je Stufe unterschiedlich und teilweise verlustbehaftet
   gespeichert.

Die JSON-Dateien ließen sich parsen. Bei der statischen Verbindungsprüfung wurden
keine bestätigten fehlenden Nodes innerhalb eines Exports gefunden.

## 2. Prüfgrenzen

Geprüft wurden:

- alle versionierten Workflow-Exporte im Repository;
- n8n-Node-Verbindungen und Sub-Workflow-Aufrufe;
- Schedule Trigger und Stufenreihenfolge;
- Zugriffe auf `allris_vorgaenge` und `allris_lernbeispiele`;
- Statusfelder und wesentliche Kandidaten-Gates;
- ALLRIS, Proxy, Nextcloud, Tika, OpenAI, Matrix, Paperless und beide
  WordPress-Ziele;
- Credentials-Konfiguration in den Exporten;
- Fehler-, Wiederholungs- und Veröffentlichungswege.

Nicht geprüft werden konnten:

- Erreichbarkeit, Version und Konfiguration der laufenden n8n-Instanz;
- tatsächlich hinterlegte Credentials und Umgebungsvariablen;
- reale Data-Table-Schemata und Constraints;
- Antworten der Live-Systeme sowie vollständige End-to-End-Ausführungen;
- Übereinstimmung der Exporte mit eventuell späteren, noch nicht exportierten
  Änderungen in n8n.

Ein grünes Ergebnis dieser Prüfung bedeutet daher „im Export konsistent“, nicht
„live erfolgreich getestet“.

## 3. Schnittstellenübersicht

| Schnittstelle | Verwendet durch | Vertrag / Kopplung | Bewertung |
|---|---|---|---|
| ALLRIS Goslar | P1, P2 | HTML-Scraping, feste URLs, interner Proxy `172.16.1.5:3128` | fragil gegenüber HTML- und Infrastrukturänderungen |
| n8n Data Tables | fast alle Stufen | feste Projekt-/Tabellen-IDs, gemeinsame Zeile über `vorgangKey` | zentrale Kopplung, aber ohne versioniertes Schema |
| n8n Sub-Workflows | P3c, P3d, P3e, P5 | feste Workflow-IDs | Exporte nicht portabel und IDs im Repository nicht auflösbar |
| Nextcloud | P2, P3, P3c, P4, P6, P8, Paperless | feste Pfadkonventionen und n8n-Credential | grundsätzlich konsistent, Fehlerstatus uneinheitlich |
| Tika | P3, P4 | `http://tika:9998/tika` | interner DNS-/Containername, keine Authentifizierung |
| OpenAI | Analyse-, Content-, Bild- und Agenten-Stufen | n8n-Credential | technisch sauber ausgelagert, Ausgaben benötigen weiterhin strikte Gates |
| Matrix | P2–P6, Watchdog | feste Raum-IDs, Header-Credential | ein bestätigter Authentifizierungsfehler in P6 |
| Paperless | Backfill | REST, Header-Credential, Titel als Dublettenprüfung | grundsätzlich geschlossen, aber kein persistierter Fehlerzustand |
| WordPress golietz.de | P7 | Credential, sofortiger Status `publish` | Kandidaten- und Freigabevertrag unklar/zu breit |
| WordPress die-partei.net | P8, produktiv aktiv gemäß DEC-004 | Credential, sofortiger Status `publish` | positives Veröffentlichungs-Gate weiterhin fachlich festlegen |
| Status-WebHook | Status-Übersicht | Query-Token aus `ALLRIS_STATUS_TOKEN` | sicherer Default, Token in URL ist jedoch log-/history-sensitiv |

## 4. Befunde

### F-01 – P6-Matrix-Aufruf verwendet das vorhandene Credential nicht

**Priorität:** kritisch  
**Betroffen:** `ALLRIS_P6_Bildgenerierung.json`, Node
`Sende Presseartikel Matrix`

Der Node enthält zwar ein `httpHeaderAuth`-Credential, in den Parametern fehlen
aber `authentication: genericCredentialType` und
`genericAuthType: httpHeaderAuth`. Anders als alle funktionierenden
Matrix-Nodes aktiviert er das Credential damit nicht.

**Auswirkung:** Der finale Presseartikel kann mit 401/403 scheitern. Wegen
`onError: continueRegularOutput` kann der Prozess anschließend regulär
weiterlaufen, ohne dass die fehlende Matrix-Nachricht als eigener Zustand
persistiert wird.

**Maßnahme:** Authentifizierung wie bei `Matrix Sende Bild` aktivieren, Antwort
explizit prüfen und `MATRIX_SEND_FAILED` persistieren.

### F-02 – P7 veröffentlicht alle ausreichend analysierten Vorgänge

**Priorität:** kritisch/fachliche Entscheidung  
**Betroffen:** `ALLRIS_P7_WordPress_Publish.json`

Das Kandidaten-Gate blockiert nur:

- `contentStage=needs_summary`;
- ausgewählte Analysefehler;
- bereits veröffentlichte oder technisch unvollständige Datensätze.

Damit sind unter anderem `watching`, `ignored`, `needs_content`,
`content_generated`, `archiving_failed` sowie nicht ausdrücklich behandelte
Fehler grundsätzlich Kandidaten. Anschließend wird direkt mit
`status: publish` veröffentlicht. Eine explizite redaktionelle Freigabe wird
nicht geprüft.

**Auswirkung:** Die Bedeutung der Relevanzentscheidung und der
Content-/QA-Stufen ist für WordPress nicht verbindlich. Ein fachlich ignorierter
oder noch nicht abschließend verarbeiteter Vorgang kann veröffentlicht werden.

**Maßnahme:** Zuerst entscheiden und dokumentieren, ob P7 ein neutrales
Vollarchiv oder ein redaktioneller Veröffentlichungskanal ist.

- Vollarchiv: eigenes Feld wie `archivePublishStage` verwenden und P7 aus
  `contentStage` entkoppeln.
- Redaktioneller Kanal: positive Whitelist, z. B. `contentStage` plus
  `publicationApprovedAt`, verwenden; zunächst als `draft`, dann freigeben.

### F-03 – Widersprüchlicher Vertrag für `sourceConflict`

**Priorität:** hoch  
**Betroffen:** P3c/QA gegenüber P6

P3c dokumentiert `sourceConflict` ausdrücklich als optional und prüft es nicht
als Pflichtfeld. P6 definiert einen SourceLock dagegen nur dann als gültig, wenn
`sourceConflict` vorhanden ist.

**Auswirkung:** Ein fachlich legitimer Vorgang ohne Konflikt kann vorgelagert
freigegeben, in der Bildgenerierung aber als ungültig bzw. reparaturbedürftig
abgewiesen werden.

**Maßnahme:** Einen kanonischen SourceLock-Vertrag definieren und in Fakten-,
QA-, Repair-, Content-, Visual- und Bildstufe identisch anwenden. Wenn
`sourceConflict` optional bleibt, darf P6 dessen Fehlen nicht blockieren.

### F-04 – Zeitplanabstände sind keine Prozessgarantie

**Priorität:** hoch  
**Betroffen:** gesamte Produktionskaskade

Aktuell läuft die Kette ungefähr:

`P1 :05 → P2 :15 → P3 :25 → P3c :28 → P3d :32 → P3e :33 → P4 :35 → P5 :45 → P6 :55 → P7 :58`

P3e hat nur eine Minute Abstand zu P3d, P4 zwei Minuten zu P3e und P7 drei
Minuten zu P6. n8n-Schedules warten nicht auf den Abschluss der vorherigen
Stufe. Bei größeren Mengen, Proxy-Verzögerungen, KI-Retries oder langsamen
Uploads laufen Stufen parallel auf derselben Zeile.

**Auswirkung:** Verarbeitung verschiebt sich mindestens in den nächsten
Fünf-Stunden-Zyklus oder schreibt auf einem veralteten Snapshot. Im ungünstigen
Fall überschreiben mehrere Stufen orthogonale Statusfelder.

**Maßnahme:** Dispatcher mit atomarer Claim-/Lease-Logik einführen. Bis dahin:
jede Stufe ausschließlich über positive Eingangszustände filtern, Statusfelder
nur in der fachlich zuständigen Stufe schreiben und Zeitstempel der direkten
Vorstufe prüfen.

### F-05 – Status- und Fehlervertrag ist nicht einheitlich

**Priorität:** hoch  
**Betroffen:** P1, P2, P3, P4, P6, P7, Paperless

Beispiele:

- `archiving_failed` wird als `contentStage` verwendet, obwohl Archivierung eine
  eigene Prozessachse ist.
- P2 lässt `contentErrorReason` bei Uploadfehlern leer und ersetzt ihn nach
  Alarmierung durch `archiving_failed_notified`.
- P6 leert bei Bildfehlern `contentErrorReason`.
- P7 schreibt Veröffentlichungsfehler als Freitext in `rawAiText`.
- Paperless unterscheidet persistent nicht zwischen „noch nicht verarbeitet“
  und „fehlgeschlagen“.

**Auswirkung:** Der letzte Schreiber kann Ursachen verdecken. Monitoring,
Retry-Entscheidungen und Ursachenstatistik sind nicht zuverlässig.

**Maßnahme:** `PAKET2_DB_SPEZIFIKATION.md` umsetzen und Fehler nicht durch
Benachrichtigungsstatus überschreiben. Zusätzlich je Achse einen eigenen
Zustand führen (`archiveStage`, `analysisStage`, `publicationStage`,
`paperlessStage`).

### F-06 – P3d verarbeitet auch `watching` und `ignored`

**Priorität:** mittel/fachliche Entscheidung  
**Betroffen:** `ALLRIS_P3d_Agenten_Kette.json`

Das Gate verlangt nur `lastAnalysisAt` und ein leeres
`judgmentChainProcessedAt`; ein `contentStage`-Filter fehlt ausdrücklich. Somit
laufen Eignungs-, Fakten-, QA- und Lernlogik auch für Vorgänge, die P3 als
`watching` oder `ignored` eingestuft hat.

**Auswirkung:** Zusätzliche KI-Kosten und eine zweite fachliche Entscheidung
nach der Relevanzanalyse. Da P3d auch `contentStage` zurückschreibt, bleibt die
Zuständigkeit für diesen Zustand unscharf.

**Maßnahme:** Festlegen, ob P3d die Relevanzentscheidung korrigieren darf. Falls
nein, nur fachlich berechtigte Eingangsstufen zulassen und `contentStage` nicht
in der Eignungsstufe schreiben.

### F-07 – Repository-Exporte bilden Sub-Workflow-IDs nicht eigenständig ab

**Priorität:** mittel  
**Betroffen:** P3c, P3d, P3e, P5 und Agenten-Exporte

Aufrufende Workflows referenzieren feste Live-IDs. Die aufgerufenen Agenten- und
Repair-Exporte besitzen dagegen kein exportiertes Top-Level-`id`, über das ein
statischer Prüfer oder eine neue n8n-Instanz die Zuordnung herstellen könnte.

**Auswirkung:** Ein Import kann formal erfolgreich sein, während Aufrufe noch
auf fremde oder nicht vorhandene Workflows zeigen.

**Maßnahme:** Eine versionierte `docs/WORKFLOW_ID_MAP.md` mit Name, Rolle,
Live-ID und Importhinweis führen; nach Import automatisiert gegen die
n8n-Instanz prüfen.

### F-08 – Feste Infrastrukturwerte sind über viele Workflows verteilt

**Priorität:** mittel  
**Betroffen:** ALLRIS-URL, Proxy, Matrix-Räume, WordPress-, Paperless- und
Tika-Endpunkte

Endpunkte und Raum-IDs sind mehrfach fest eingebaut. Änderungen müssen in
mehreren JSON-Dateien synchron erfolgen.

**Auswirkung:** Konfigurationsdrift und teilweise Migrationen sind
wahrscheinlich.

**Maßnahme:** Nicht geheime Werte in n8n-Variablen oder einer zentralen
Konfiguration führen; Credentials weiterhin ausschließlich im Credential Store.

### F-09 – Status-WebHook verwendet ein Query-Token

**Priorität:** niedrig bis mittel  
**Betroffen:** `ALLRIS_Status_Uebersicht.json`

Der sichere Default bei fehlender Umgebungsvariable ist positiv. Query-Parameter
werden jedoch häufig in Browserhistorien, Reverse-Proxy- und Zugriffslogs
gespeichert.

**Maßnahme:** Wenn betrieblich möglich, Token über `Authorization`-Header oder
vorgelagerte Authentifizierung transportieren.

### F-10 – Dokumentation und produktiver Ablauf sind nicht synchron

**Priorität:** mittel  
**Betroffen:** `README.md`

P3e fehlt in Überschrift, Pipeline-Tabelle und dokumentierter
Zeitplan-Kaskade. Auch Dispatcher/Watchdog und seine inaktive Rolle sind nicht
im Hauptüberblick beschrieben.

**Auswirkung:** Claude, Codex und menschliche Betreiber arbeiten mit einem
unvollständigen Prozessbild.

**Maßnahme:** Nach Klärung von F-02 und F-06 den README-Prozessplan
aktualisieren.

## 5. Positive Befunde

- Credentials sind nicht als Klartext-Secrets in den Exporten abgelegt.
- Der Status-WebHook schlägt bei fehlender Token-Variable geschlossen fehl.
- P2 prüft Uploadmengen und begrenzt seine Wiederholungen.
- Paperless markiert einen Vorgang erst nach einer Ergebnisaggregation als
  vollständig.
- P4 und P6 besitzen mehrere deterministische Quellen- und Qualitätsprüfungen.
- Die Aufteilung von Content-, Sharepic-, Headline-, Prompt- und Bildstatus ist
  gegenüber einem einzigen Mischstatus eine klare Verbesserung.
- Veröffentlichungs- und Bildstufen sind als separate Workflows isoliert.

## 6. Empfohlene Reihenfolge

1. **Sofort:** F-01 beheben und Matrix-Aufruf mit kontrolliertem Test prüfen.
2. **Vor weiteren Veröffentlichungen:** fachliche Entscheidung zu F-02 treffen
   und P7-Gate entsprechend schließen.
3. **Danach:** F-03 vereinheitlichen und Regressionstest für einen Vorgang ohne
   `sourceConflict` ergänzen.
4. **Dann:** Fehlerhistorie und stabile Codes aus Paket 2 umsetzen.
5. **Anschließend:** Dispatcher/Lease-Konzept für F-04 realisieren.
6. **Zum Abschluss:** ID-/Konfigurationslandkarte und automatisierte
   Export-Strukturtests ergänzen.

## 7. Minimale Abnahmetests

- Jeder JSON-Export ist parsebar.
- Jede Verbindung zeigt auf einen vorhandenen Node.
- Jeder Sub-Workflow-Aufruf lässt sich über eine versionierte ID-Landkarte
  auflösen.
- Kein Matrix-Aufruf ohne aktivierte Authentifizierung.
- Kein WordPress-`publish` ohne den festgelegten positiven Freigabestatus.
- Vorgang ohne `sourceConflict` durchläuft alle Stufen gemäß dem kanonischen
  Vertrag.
- Gleichzeitige Läufe können dieselbe Zeile nicht doppelt claimen.
- Jeder externe Fehler erzeugt stabilen Code, Stufe, Zeit, Retry-Zähler und
  Historieneintrag, ohne die ursprüngliche Ursache zu überschreiben.
