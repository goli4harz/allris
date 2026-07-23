# ALLRIS – Kanonischer SourceLock-Vertrag

Stand: 2026-07-23

Der SourceLock bindet generierte Texte und Bilder an belegbare Inhalte der
ALLRIS-Quelle. Derselbe Vertrag gilt in Fakten-, Repair-, QA-, Content-,
Visual- und Bildstufe.

## Pflichtfelder

- `sourceTopic`: konkretes, belegbares Sachthema
- `requiredTerms`: mindestens zwei konkrete Quellenbegriffe
- `requiredObjects`: mindestens zwei konkrete, darstellbare Objekte
- `requiredAction`: konkrete Handlung oder Konsequenz
- `sourceLockValid`: `true`, nachdem die Pflichtfelder geprüft wurden

## Optionale Felder

- `sourceConflict`: belegbarer Konflikt oder belegbares Problem; leerer String,
  wenn die Quelle keinen Konflikt enthält
- `affectedGroups`
- `concreteNumbers`
- `responsibilities`
- `documentType`
- `quotesVerbatim`
- `forbiddenDrift`

Ein leerer `sourceConflict` macht den SourceLock nicht ungültig und darf weder
Repair noch Content-, Visual- oder Bildblockaden auslösen. Ist ein Konflikt
vorhanden, bleibt er ein verbindlicher Quellenanker und darf nicht durch einen
anderen Konflikt ersetzt werden.

Generierende Agenten dürfen keinen Konflikt erfinden. Bei konfliktlosen
Mitteilungen müssen sie ihre Zuspitzung aus belegbaren Begriffen, Objekten,
Handlungen, Zahlen oder Zitaten ableiten.

