// ============================================================
// KANONISCHE GUARD-KONSTANTEN (P3, RatsPilot-Folgeauftrag, 2026-09-03)
// ============================================================
// Einzige Quelle der Wahrheit fuer die Regex-Fragmente, die den echten
// Guard-Divergenz-Bug vom 2026-09-01 verursacht haben (siehe Memory
// allris_guard_unification_2026-09-01) - NICHT der komplette Guard-Code,
// nur die Werte, die nachweislich schon einmal auseinandergedriftet sind
// bzw. bei der Konsolidierung am 2026-09-03 als aktuell auseinandergedriftet
// gefunden wurden. n8n Code-Nodes koennen zur Laufzeit nichts importieren -
// diese Datei ist daher die Quelle fuer scripts/Sync-AllrisGuardConstants.js,
// nicht selbst Teil eines live laufenden Workflows.
//
// Aenderung hier + `node scripts/Sync-AllrisGuardConstants.js --apply` +
// `node scripts/Sync-AllrisGuardConstants.js` (Check-Modus, muss danach
// leer/gruen sein) ist der einzige vorgesehene Weg, diese Werte zu aendern -
// nie direkt in einer der 8 Node-Kopien editieren, das schafft sofort
// wieder Drift.

module.exports = {
  // Woerter/Stammformen, die einen Vorgang als "sensibler Kontext" markieren.
  // Bug 2026-09-01: bare Staemme ohne \w*-Suffix matchten nicht mitten im
  // Wort ("Behinderung"/"Geflüchtete" bei Family B, "wohnungslose" bei
  // Family A) - seither ueberall mit \w*-Suffix auf jedem Stamm.
  SENSITIVE_CONTEXT_STEMS:
    'minderjaehrig\\w*|kind\\w*|schueler\\w*|behinder\\w*|barrierefrei\\w*|' +
    'blind\\w*|sehbehindert\\w*|taub\\w*|krank\\w*|pflege\\w*|rollstuhl\\w*|' +
    'gefluechtet\\w*|wohnungslos\\w*|obdachlos\\w*|armut\\w*|opfer\\w*|notlage\\w*',

  // Wortfenster (Zeichen) zwischen "barrierefreiheit" und einem der
  // METAPHOR_TRIGGER_WORDS, innerhalb dessen ein Metapher-Missbrauch erkannt
  // wird (z.B. "Barrierefreiheit... ist doch nur uebertriebene Forderung").
  METAPHOR_WINDOW_CHARS: 60,

  // Trigger-Woerter fuer Metapher-Missbrauch nach dem Fenster oben. Bewusst
  // NUR die ASCII/transliterierte Form (kein "ß"/"spasz") - normalizeText()
  // wandelt ß->ss VOR der Pruefung um, ein woertliches "ß" im Pattern ist
  // damit tote Zeichenkette. Gefunden 2026-09-03 in ALLRIS_P3_Bewertung
  // ("Parse Analyse JSON"): dort stand zusaetzlich spasz/spaß/übertriebene
  // forderung im Pattern - behavioral aequivalent, aber unnoetige,
  // driftende Redundanz. Hier bewusst vereinheitlicht auf die einfachere,
  // in 7 von 8 Instanzen bereits verwendete Form.
  METAPHOR_TRIGGER_WORDS: 'luxus|spass|teurer spass|uebertriebene forderung',

  // Woerter, die (zusammen mit einem sensiblen Personenbegriff in der Naehe,
  // siehe containsSensitiveScene/-Metaphor) einen blinden Fleck markieren -
  // z.B. "blinde Flecken in der Verwaltung", "taube Ohren im Rathaus".
  BLIND_TRIGGER_WORDS:
    'augen|sparschwein|haushalt|verwaltung|planung|politik|ampel|stadt|verfahren|rathaus',

  // Erkennt eine sensible Person als Pflichtobjekt/requiredObject
  // (containsSensitivePerson/isSensitivePersonObject). Gefunden 2026-09-03,
  // unabhaengig vom 2026-09-01-Fix: Family B (6 von 8 Kopien) zaehlte
  // einzelne Beugungsformen woertlich auf statt Stammformen zu nutzen,
  // UND mischte dabei woertliche Umlaut-Varianten ("schüler"/"geflüchtete"/
  // "minderjährige"/"pflegebedürftige") ein, die wegen der vorgeschalteten
  // ae/oe/ue-Normalisierung NIE greifen konnten (totes Muster - dieselbe
  // Bugklasse wie METAPHOR_TRIGGER_WORDS oben). Family A (2 Kopien) hatte
  // dafuer mehr echte Beugungsformen (blindem/blinden/behinderten/
  // schuelerinnen/schuelern/wohnungsloser/obdachloser), war aber ihrerseits
  // nicht vollstaendig. Statt beide Aufzaehlungen zu vereinigen (fragil,
  // naechste fehlende Form ist nur eine Frage der Zeit): auf \w*-Wortstaemme
  // umgestellt, exakt dieselbe Technik wie beim SENSITIVE_CONTEXT_STEMS-Fix
  // vom 2026-09-01 - deckt strukturell jede Beugungsform ab, nicht nur die
  // gerade bekannten. "menschen? mit behinderung\w*" deckt zusaetzlich
  // "Menschen mit Behinderungen" (Plural) ab, das keine der beiden alten
  // Listen hatte.
  // "kind" bewusst NICHT als \w*-Stamm ("kind\w*" matcht "kindergarten" als
  // Substring - Kindergarten/-tagesstaette sind in einer Kommunalpipeline
  // haeufige, meist NICHT auf ein Kind als sensible Person bezogene
  // Sachbegriffe). "kind(er|es|ern)?" trifft echte Beugungsformen
  // (kind/kinder/kindes/kindern), \b danach verhindert das Reinlaufen in
  // "kindergarten" (kein Wortgrenze zwischen "kinder" und "garten").
  SENSITIVE_PERSON_STEMS:
    'blind\\w*|sehbehindert\\w*|behindert\\w*|mensch(en)? mit behinderung\\w*|' +
    'schueler\\w*|kind(er|es|ern)?|minderjaehrig\\w*|patient\\w*|pflegebeduerftig\\w*|' +
    'rollstuhlfahrer\\w*|gefluechtet\\w*|wohnungslos\\w*|obdachlos\\w*|krank\\w*',
};
