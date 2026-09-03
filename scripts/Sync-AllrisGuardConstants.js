// ============================================================
// Sync-AllrisGuardConstants.js (P3, RatsPilot-Folgeauftrag, 2026-09-03)
// ============================================================
// Schreibt die kanonischen Werte aus shared/guard-constants.js in alle 8
// bekannten Guard-Kopien (siehe TARGETS unten). Musterbasiert, nicht
// zeilenverankert: findet den bestehenden Regex-Baustein an stabilen
// Start-/End-Markern (z.B. "minderjaehrig...notlage\w*" fuer den
// Sensible-Kontext-Stamm) und ersetzt NUR den Inhalt dazwischen - so
// funktioniert derselbe Sync unabhaengig davon, ob eine Stelle die
// Zuweisung inline (`.test(text)`) oder getrennt (`const X = /.../i;`)
// schreibt.
//
// Standard: Check-Modus (zeigt Diffs, schreibt nichts, Exit-Code 1 bei
// Abweichungen). --apply schreibt tatsaechlich in die lokalen Workflow-
// Dateien (NICHT live - das PUSHen zu n8n bleibt ein separater, bewusster
// Schritt danach, mit Backup+Verifikation wie bei jeder anderen Aenderung
// in diesem Repo).
//
// Aufruf:
//   node scripts/Sync-AllrisGuardConstants.js            (Check, CI-tauglich)
//   node scripts/Sync-AllrisGuardConstants.js --apply    (schreibt lokal)

const fs = require('fs');
const path = require('path');

const REPO_ROOT = path.resolve(__dirname, '..');
const C = require(path.join(REPO_ROOT, 'shared', 'guard-constants.js'));
const APPLY = process.argv.includes('--apply');

const TARGETS = [
  ['ALLRIS_P3_Bewertung.json', 'Parse Analyse JSON'],
  ['ALLRIS_QA_Agent.json', 'Deterministische Regelprüfung'],
  ['ALLRIS_P4_Content_Reaktion.json', 'Repariere Legacy Visual-Status'],
  ['ALLRIS_P4_Content_Reaktion.json', 'Filtere unbenachrichtigte Blockaden'],
  ['ALLRIS_P5b_Matrix_Headline_Reader.json', 'Finde Blockade-Antwort'],
  ['ALLRIS_P3b_Repair_SourceLock_VisualGuard.json', 'Parse Reparatur JSON'],
  ['ALLRIS_P3b_Repair_SourceLock_VisualGuard.json', 'Prüfe Guard-Repair-Bedarf'],
  ['ALLRIS_P3b_Repair_SourceLock_VisualGuard.json', 'Parse Guard-Reparatur JSON'],
];

// Jedes Muster: findet den Block zwischen START und END (beide als Literal-
// Marker, nicht als Regex) und ersetzt alles dazwischen durch `value`.
// `required: false` erlaubt, dass ein Muster an einer Stelle fehlt (nicht
// jede der 8 Kopien nutzt zwingend jede Funktion).
function buildPatterns() {
  return [
    { name: 'SENSITIVE_CONTEXT_STEMS', start: 'minderjaehrig\\w*', end: 'notlage\\w*', value: C.SENSITIVE_CONTEXT_STEMS, required: true },
    { name: 'SENSITIVE_PERSON_STEMS', start: 'blind', endRe: /kranker\|kranke\)/, value: C.SENSITIVE_PERSON_STEMS, required: true, wholeGroup: true },
    { name: 'BLIND_TRIGGER_WORDS', start: 'augen|sparschwein', end: 'rathaus', value: C.BLIND_TRIGGER_WORDS, required: false },
    { name: 'METAPHOR_TRIGGER_WORDS', startRe: /\(luxus\|spass/, value: C.METAPHOR_TRIGGER_WORDS, required: false, upToCloseParen: true },
  ];
}

function replaceBetweenMarkers(code, startLit, endLit) {
  const startIdx = code.indexOf(startLit);
  if (startIdx === -1) return null;
  const searchFrom = startIdx + startLit.length;
  const endIdx = code.indexOf(endLit, searchFrom);
  if (endIdx === -1) return null;
  const blockStart = startIdx;
  const blockEnd = endIdx + endLit.length;
  return { blockStart, blockEnd, old: code.slice(blockStart, blockEnd) };
}

function replaceUpToCloseParen(code, startRe) {
  const m = startRe.exec(code);
  if (!m) return null;
  const openIdx = m.index + m[0].indexOf('(');
  const closeIdx = code.indexOf(')', m.index);
  if (closeIdx === -1) return null;
  return { blockStart: openIdx + 1, blockEnd: closeIdx, old: code.slice(openIdx + 1, closeIdx) };
}

function replaceWholeGroup(code, startLit, endRe) {
  // Findet jede "(blind...)"-Gruppe ueber Klammer-Balance (nicht ueber ein
  // naives [^)]*, das an der ersten inneren Klammer abbricht - der
  // kanonische Ersatzwert selbst kann verschachtelte Klammern enthalten,
  // z.B. "mensch(en)?"). Nimmt die erste so gefundene Gruppe, deren Inhalt
  // mit dem End-Marker (z.B. "kranker|kranke)") uebereinstimmt - das
  // unterscheidet die containsSensitivePerson-Personenliste von der
  // aehnlich beginnenden BLIND_TRIGGER-Stelle ("blind(e|er|es|en)?").
  let searchFrom = 0;
  while (true) {
    const openIdx = code.indexOf('(' + startLit, searchFrom);
    if (openIdx === -1) return null;
    let depth = 0;
    let closeIdx = -1;
    for (let i = openIdx; i < code.length; i++) {
      if (code[i] === '(') depth++;
      else if (code[i] === ')') { depth--; if (depth === 0) { closeIdx = i; break; } }
    }
    if (closeIdx === -1) return null;
    const whole = code.slice(openIdx, closeIdx + 1);
    if (endRe.test(whole)) {
      return { blockStart: openIdx + 1, blockEnd: closeIdx, old: code.slice(openIdx + 1, closeIdx) };
    }
    searchFrom = openIdx + 1;
  }
}

function findReplacement(code, pattern) {
  if (pattern.wholeGroup) return replaceWholeGroup(code, pattern.start, pattern.endRe);
  if (pattern.upToCloseParen) return replaceUpToCloseParen(code, pattern.startRe);
  return replaceBetweenMarkers(code, pattern.start, pattern.end);
}

let anyDiff = false;
let anyError = false;

for (const [fileName, nodeName] of TARGETS) {
  const filePath = path.join(REPO_ROOT, fileName);
  const workflow = JSON.parse(fs.readFileSync(filePath, 'utf8'));
  const node = workflow.nodes.find(n => n.name === nodeName);
  if (!node) {
    console.log(`FEHLER: Node "${nodeName}" nicht in ${fileName} gefunden.`);
    anyError = true;
    continue;
  }

  let code = node.parameters.jsCode;
  let changedHere = false;

  for (const pattern of buildPatterns()) {
    // Kurzschluss zuerst: steht der kanonische Wert schon exakt so im Code,
    // ist nichts zu tun - erspart den fragileren Marker-Abgleich unten, der
    // auf die Form des ALTEN Inhalts zugeschnitten ist und nach einer
    // Ersetzung (z.B. wenn der neue Wert selbst Klammern enthaelt) nicht
    // mehr zuverlaessig wiederfindet, wo der Block war.
    if (code.includes(pattern.value)) continue;

    const found = findReplacement(code, pattern);
    if (!found) {
      if (pattern.required) {
        console.log(`FEHLER: Muster "${pattern.name}" nicht gefunden in ${fileName} :: ${nodeName}`);
        anyError = true;
      }
      continue;
    }
    if (found.old !== pattern.value) {
      anyDiff = true;
      console.log(`DIFF [${pattern.name}] in ${fileName} :: ${nodeName}`);
      console.log(`  alt: ${found.old}`);
      console.log(`  neu: ${pattern.value}`);
      code = code.slice(0, found.blockStart) + pattern.value + code.slice(found.blockEnd);
      changedHere = true;
    }
  }

  if (changedHere && APPLY) {
    node.parameters.jsCode = code;
    fs.writeFileSync(filePath, JSON.stringify(workflow, null, 2), 'utf8');
    console.log(`GESCHRIEBEN: ${fileName} :: ${nodeName}`);
  }
}

console.log('');
if (anyError) {
  console.log('Mindestens ein erforderliches Muster fehlte - siehe FEHLER oben.');
  process.exit(2);
}
if (!anyDiff) {
  console.log('Keine Abweichungen - alle 8 Kopien stimmen mit shared/guard-constants.js ueberein.');
  process.exit(0);
}
console.log(APPLY ? 'Alle Abweichungen wurden geschrieben.' : 'Abweichungen gefunden (siehe oben). Zum Schreiben: --apply anhaengen.');
process.exit(APPLY ? 0 : 1);
