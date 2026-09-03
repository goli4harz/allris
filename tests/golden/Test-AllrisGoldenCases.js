// ============================================================
// P2.5 GOLDEN TEST SET (RatsPilot-Folgeauftrag 2026-09-01, gebaut 2026-09-03)
// ============================================================
// Ziel (Auftragstext): "bekannte historische Bugklassen reproduzierbar
// absichern" - jeder der 6 Faelle ist an einen echten, bereits diagnostizierten
// und gefixten Vorfall aus diesem Projekt angebunden, nicht an einem
// generischen Beispiel. Reine Funktions-Tests: das jeweilige Code-Node-JS wird
// WORTWOERTLICH aus der lokalen Workflow-Datei extrahiert (keine
// handkopierten Snippets, die mit der Zeit vom echten Code abdriften koennten)
// und in einer isolierten vm-Sandbox laufen gelassen. Keine Live-Ausfuehrung,
// kein n8n-API-Aufruf, kein echter Post - nichts hier kann jemals live etwas
// veroeffentlichen oder eine Matrix-Nachricht verschicken.
//
// Aufruf: node tests/golden/Test-AllrisGoldenCases.js
// Exit-Code 0 = alle Faelle gruen, 1 = mindestens ein Fall rot.

const fs = require('fs');
const path = require('path');
const vm = require('vm');

const REPO_ROOT = path.resolve(__dirname, '..', '..');

let passed = 0;
let failed = 0;
const failures = [];

function loadWorkflow(fileName) {
  const p = path.join(REPO_ROOT, fileName);
  return JSON.parse(fs.readFileSync(p, 'utf8'));
}

function getNodeCode(workflow, nodeName) {
  const node = workflow.nodes.find(n => n.name === nodeName);
  if (!node) throw new Error(`Node "${nodeName}" nicht gefunden`);
  return node.parameters.jsCode;
}

// Fuehrt Code eines "Run Once for All Items"-Nodes aus: Code referenziert
// $input.all() und endet mit `return <array>;`.
function runAllItems(code, itemsJson) {
  const wrapped = itemsJson.map(j => ({ json: j }));
  const sandbox = {
    // Manche Nodes nutzen n8ns implizit gebundenes "items", andere rufen
    // $input.all() selbst auf - beide auf dieselben Daten zeigen lassen.
    items: wrapped,
    $input: { all: () => wrapped },
    console,
  };
  vm.createContext(sandbox);
  const script = new vm.Script('(function(){\n' + code + '\n})()');
  return script.runInContext(sandbox);
}

// Fuehrt Code eines "Run Once for Each Item"-Nodes aus: Code referenziert
// $json fuer genau ein Item und endet mit `return { json: {...} };`.
function runEachItem(code, item) {
  const sandbox = { $json: item, console };
  vm.createContext(sandbox);
  const script = new vm.Script('(function(){\n' + code + '\n})()');
  return script.runInContext(sandbox);
}

function assert(condition, caseName, message) {
  if (condition) {
    passed++;
    console.log(`PASS: ${caseName} - ${message}`);
  } else {
    failed++;
    failures.push(`${caseName}: ${message}`);
    console.log(`FAIL: ${caseName} - ${message}`);
  }
}

// ------------------------------------------------------------
// Fall 1: normaler topic_ok (Kontrollfall)
// ------------------------------------------------------------
// Kein Bug-Regressionstest, sondern die Gegenprobe: eine gesunde Zeile darf
// von keinem der Blockier-Fixes in Faellen 2/5 versehentlich mit erfasst
// werden. Node: ALLRIS_P5_Visual_Prompt_Builder / "Filtere Visual-Status".
(function case1() {
  const wf = loadWorkflow('ALLRIS_P5_Visual_Prompt_Builder.json');
  const code = getNodeCode(wf, 'Filtere Visual-Status');
  const gesund = {
    vorgangKey: 'golden_case1', sharepicNeedStage: 'topic_ok',
    imageStage: 'not_started', visualPromptStage: 'needs_prompt',
    headlineChoiceStage: '', visualForceReset: false,
  };
  const out = runAllItems(code, [gesund]);
  assert(out.length === 1 && out[0].json.vorgangKey === 'golden_case1',
    'Fall 1 (topic_ok, Kontrollfall)',
    'gesunde Zeile (topic_ok/needs_prompt) muss den Filter passieren');
})();

// ------------------------------------------------------------
// Fall 2: not_applicable
// ------------------------------------------------------------
// Realfall: FIX 2026-07-26, Vorgang 2026/109. Vor dem Fix liessen not_applicable-
// Zeilen "Pruefe Content-Abschluss" jede Stunde erneut anlaufen, wobei der
// eigentliche (aussagekraeftigere) Blockierungsgrund durch eine generische
// CONTENT_JSON_INVALID-Meldung ueberschrieben wurde.
(function case2() {
  const wf = loadWorkflow('ALLRIS_P5_Visual_Prompt_Builder.json');
  const code = getNodeCode(wf, 'Filtere Visual-Status');
  const notApplicable = {
    vorgangKey: 'golden_case2', sharepicNeedStage: 'not_applicable',
    imageStage: 'not_started', visualPromptStage: 'needs_prompt',
    headlineChoiceStage: '', visualForceReset: false,
  };
  const out = runAllItems(code, [notApplicable]);
  assert(out.length === 0,
    'Fall 2 (not_applicable, Realfall 2026/109)',
    'sharepicNeedStage=not_applicable darf "Prepare Visual Prompt Input" nie erreichen');
})();

// ------------------------------------------------------------
// Fall 3: qa_blocked
// ------------------------------------------------------------
// Realfall: FIX 2026-09-01 (commit 158602f), Vorgang 2026/109 (37 Tage
// unbemerkt). "Repariere Legacy Visual-Status" rechnete sharepicNeedStage fuer
// jede topic_error/blocked_source_lock-Zeile aus gespeichertem
// eignungsAgentJson neu - dabei wurde ein frischer QA-Agent-Infrastruktur-
// ausfall (contentErrorReason=qa_blocked) silently auf 'not_applicable'
// umklassifiziert und damit geloescht. Node: ALLRIS_P4_Content_Reaktion.
(function case3() {
  const wf = loadWorkflow('ALLRIS_P4_Content_Reaktion.json');
  const code = getNodeCode(wf, 'Repariere Legacy Visual-Status');
  const qaBlocked = {
    vorgangKey: 'golden_case3', sharepicNeedStage: 'topic_error',
    contentErrorReason: 'qa_blocked',
  };
  const out = runAllItems(code, [qaBlocked]);
  assert(out.length === 0,
    'Fall 3 (qa_blocked, Realfall 2026/109)',
    'contentErrorReason=qa_blocked darf vom Legacy-Repair nie umklassifiziert werden');
})();

// ------------------------------------------------------------
// Fall 4: sensible Gruppe
// ------------------------------------------------------------
// Realfall: FIX 2026-09-01 (Guard-Vereinheitlichung, commits f6619b1+a41ee666).
// Family A (u.a. ALLRIS_QA_Agent) hatte 'wohnungslos' (nicht 'wohnungslose')
// als bloßen Wortstamm in einer \b(...)\b-Alternation - das \b direkt nach dem
// Stamm verlangt eine Wortgrenze GENAU dort, matcht also nie mitten im Wort
// ("wohnungslose" hat ein "e" danach). Family B hatte denselben Bugtyp fuer
// 'behinder'/'gefluecht'. Getestet hier: Family A / ALLRIS_QA_Agent /
// "Deterministische Regelpruefung", seit dem Fix mit \w*-Suffix auf allen
// Stammformen. Live-Regression bestaetigt: dieselbe Fixture liefert gegen
// den PRE_GUARDUNIFY-Stand (n8n_live_backup, 2026-09-01) KEINE
// guard_sensitive_object-Verletzung, gegen den aktuellen Stand schon.
(function case4() {
  const wf = loadWorkflow('ALLRIS_QA_Agent.json');
  const code = getNodeCode(wf, 'Deterministische Regelprüfung');
  const sensibel = {
    vorgangKey: 'golden_case4',
    sourceLock: {
      sourceTopic: 'Wohnraumsituation in Goslar',
      requiredTerms: ['Wohnraum', 'Notunterkunft'],
      requiredObjects: ['Wohnungsloser'],
      requiredAction: 'Unterstuetzung',
      affectedGroups: [],
    },
    visualAnchors: {},
    qaStage: 'content',
    sourceFactsText: 'Der Sozialausschuss diskutierte Massnahmen zur Unterbringung ' +
      'wohnungslose Familien in der neuen Notunterkunft.',
    contentUnderReview: '',
  };
  const out = runEachItem(code, sensibel);
  const violationCodes = (out.json.deterministicViolations || []).map(v => v.code);
  assert(violationCodes.includes('guard_sensitive_object'),
    'Fall 4 (sensible Gruppe, Realfall "wohnungslose")',
    'requiredObjects=[Wohnungsloser] + Quelltext mit "wohnungslose" muss guard_sensitive_object ausloesen (Violations: ' + JSON.stringify(violationCodes) + ')');
})();

// ------------------------------------------------------------
// Fall 5: Bildgenerierungsfehler
// ------------------------------------------------------------
// Realfall: FIX 2026-08-23, Vorgaenge 2026/010 und 2026/099. Ein endgueltig
// aufgegebenes Bildkonzept (imageStage=topic_error_final) fehlte in
// ALREADY_COMPOSED_STAGES und wurde dadurch jede Stunde erneut (kostenpflichtig)
// neu generiert, obwohl P6 es laengst final aufgegeben hatte.
(function case5() {
  const wf = loadWorkflow('ALLRIS_P5_Visual_Prompt_Builder.json');
  const code = getNodeCode(wf, 'Filtere Visual-Status');
  const aufgegeben = {
    vorgangKey: 'golden_case5a', sharepicNeedStage: 'topic_ok',
    imageStage: 'topic_error_final', visualPromptStage: 'needs_prompt',
    headlineChoiceStage: '', visualForceReset: false,
  };
  const outBlocked = runAllItems(code, [aufgegeben]);
  assert(outBlocked.length === 0,
    'Fall 5a (Bildgenerierungsfehler final, Realfall 2026/010+2026/099)',
    'imageStage=topic_error_final darf ohne visualForceReset nie erneut generiert werden');

  const manuellerReset = { ...aufgegeben, vorgangKey: 'golden_case5b', visualForceReset: true };
  const outReset = runAllItems(code, [manuellerReset]);
  assert(outReset.length === 1,
    'Fall 5b (Bildgenerierungsfehler, manueller Reset-Schalter)',
    'visualForceReset=true muss den Ausschluss weiterhin gezielt aufheben koennen');
})();

// ------------------------------------------------------------
// Fall 6: Publishing-/P8-Fall
// ------------------------------------------------------------
// Realfall: Fast-Lane P2 (RatsPilot-Folgeauftrag 2026-09-01). "hold" ist eine
// bewusste menschliche Zurueckhaltung per Matrix (-HOLD) und darf nie
// automatisch ausgewaehlt werden; "fast" (-FAST bestaetigt) hat Vorrang vor
// der chronologischen Normalreihenfolge. Node: ALLRIS_P8b_Tagesveroeffentlichung.
(function case6() {
  const wf = loadWorkflow('ALLRIS_P8b_Tagesveroeffentlichung.json');
  const code = getNodeCode(wf, 'Waehle naechsten Draft');
  const kandidaten = [
    { vorgangKey: 'normal_alt', wordpressGoslarDraftId: 'd1', wordpressGoslarPosted: false, publicationMode: '', vorlageDatum: '2026-08-01' },
    { vorgangKey: 'zurueckgehalten', wordpressGoslarDraftId: 'd2', wordpressGoslarPosted: false, publicationMode: 'hold', vorlageDatum: '2026-07-01' },
    { vorgangKey: 'bestaetigt_schnell', wordpressGoslarDraftId: 'd3', wordpressGoslarPosted: false, publicationMode: 'fast', vorlageDatum: '2026-08-15' },
    { vorgangKey: 'normal_neu', wordpressGoslarDraftId: 'd4', wordpressGoslarPosted: false, publicationMode: '', vorlageDatum: '2026-08-10' },
  ];
  const out = runAllItems(code, kandidaten);
  const outKeys = out.map(i => i.json.vorgangKey);
  assert(!outKeys.includes('zurueckgehalten'),
    'Fall 6a (Publishing/P8b, hold nie automatisch)',
    '"hold" darf nie in der Auswahl landen (Auswahl: ' + JSON.stringify(outKeys) + ')');
  assert(outKeys[0] === 'bestaetigt_schnell',
    'Fall 6b (Publishing/P8b, fast hat Vorrang)',
    '"fast" muss vor der normalen chronologischen Reihenfolge stehen (Auswahl: ' + JSON.stringify(outKeys) + ')');
})();

// ------------------------------------------------------------
console.log('');
console.log(`${passed} bestanden, ${failed} fehlgeschlagen (von ${passed + failed} Assertions).`);
if (failed > 0) {
  console.log('Fehlgeschlagen:');
  failures.forEach(f => console.log('  - ' + f));
  process.exit(1);
}
process.exit(0);
