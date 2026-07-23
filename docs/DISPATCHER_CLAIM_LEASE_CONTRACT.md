# Dispatcher Claim-/Lease-Vertrag

Dieser Vertrag ergänzt die fachlichen Statusfelder auf `allris_vorgaenge`.
Er ersetzt sie nicht. Ein Claim regelt ausschließlich, welcher Workflow-Lauf
einen Vorgang momentan bearbeiten darf.

## Felder

| Feld | Typ | Bedeutung |
|---|---|---|
| `claim_owner` | string | Eindeutige Lauf-ID, Format `<workflow>:<execution-id>` |
| `claim_stage` | string | Pipeline-Stufe aus dem State-History-Vertrag |
| `claim_acquired_at` | string | Erwerbszeit als ISO-Zeitstempel |
| `claim_expires_at` | string | Ende der Lease als ISO-Zeitstempel |

Alle vier Felder sind leer, wenn kein Claim besteht. Secrets, Hostnamen und
personenbezogene Daten gehören nicht in diese Felder.

## Erwerb

1. Der Dispatcher liest nur Vorgänge mit positivem Eingangszustand für die
   nächste Stufe.
2. Für jeden Kandidaten erzeugt er einen eindeutigen `claim_owner`.
3. Der Claim wird mit **einem** Data-Table-Update erworben. Dessen Filter
   enthält mindestens:
   - `vorgangKey = <Kandidat>`
   - `claim_owner = <zuvor gelesener Wert>`
   - `claim_expires_at = <zuvor gelesener Wert>`
4. Direkt danach liest der Dispatcher den Vorgang erneut. Nur wenn
   `claim_owner` exakt der eigenen Lauf-ID entspricht, darf er die Stufe
   starten.

Die erwarteten alten Werte machen das Update zu Compare-and-set. Zwei
gleichzeitige Dispatcher können denselben gelesenen Zustand nicht beide
erfolgreich als eigenen Claim bestätigen.

## Lease-Dauer und Verlängerung

- Standarddauer: 30 Minuten.
- Lang laufende Archiv- und Bildstufen: 60 Minuten.
- Verlängerung nur mit einem Update, dessen Filter den eigenen
  `claim_owner` enthält.
- Eine Stufe darf niemals einen fremden Claim verlängern oder löschen.

## Freigabe

Erfolg und endgültiger Fehler leeren alle vier Claim-Felder. Das Update muss
neben `vorgangKey` den eigenen `claim_owner` filtern. Fachliche Status-,
Fehler- und History-Änderungen werden im selben Abschlusszweig geschrieben.

## Abgelaufene Claims

Ein abgelaufener Claim darf neu übernommen werden. Auch hier werden der zuvor
gelesene Owner und Ablaufwert im Update-Filter verwendet. Der neue Owner prüft
anschließend durch erneutes Lesen, ob die Übernahme wirklich erfolgreich war.

Der Watchdog meldet Claims, deren `claim_expires_at` abgelaufen ist. Er löscht
sie nicht blind, weil ein inzwischen verlängerter Claim sonst überschrieben
werden könnte.

## Einführungsreihenfolge

1. Felder additiv anlegen und vorhandene Workflows unverändert weiterlaufen
   lassen.
2. Dispatcher als inaktiven manuellen Testworkflow mit Claim, Re-Read und
   kontrollierter Freigabe aufbauen.
3. Gleichzeitigen Doppelclaim sowie Übernahme eines abgelaufenen Claims testen.
4. Stufen einzeln auf Dispatcher-Eingang und eigene Claim-Freigabe umstellen.
5. Erst nach vollständiger Abnahme die reine Zeitplansteuerung zurücknehmen.

Während der Migration bleiben die bestehenden positiven Eingangszustände
verbindlich. Ein Claim allein ist niemals eine fachliche Freigabe.
