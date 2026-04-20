/* Specimen Prototype — logic & interactions
   Each puzzle has 4 slots, 4 organs in inventory, and an answer key.
   Player taps an organ card to select it, then taps a slot to place it.
   Run Simulation validates; wrong answers trigger one of 3 outcome sequences.
*/

// ---- Puzzle definition ----------------------------------------------------

const ORGAN_TYPES = {
  vordex:   { name: "Vordex Emitter",   short: "VDX", role: "source",   color: "var(--organ-vordex)",   desc: "Bioelectric source. Pacemaker: emits without input." },
  valdris:  { name: "Valdris Gate",     short: "VLD", role: "gate",     color: "var(--organ-valdris)",  desc: "Biological AND gate. Transmits when both channels are live." },
  thrennic: { name: "Thrennic Splitter",short: "THR", role: "splitter", color: "var(--organ-thrennic)", desc: "Signal duplicator. Copies PULSE into two outputs." },
  ossuric:  { name: "Ossuric Terminus", short: "OSS", role: "sink",     color: "var(--organ-ossuric)",  desc: "Signal terminator. Consumes; no output." },
};

// Slots & channels: creature-relative (x% / y% of viewer box).
const PUZZLE = {
  title: "Specimen 04 — Vorrkai",
  slots: [
    { id: "s1", x: 48, y: 22, answer: "vordex"   }, // top: source
    { id: "s2", x: 24, y: 48, answer: "thrennic" }, // left: splitter
    { id: "s3", x: 72, y: 48, answer: "valdris"  }, // right: gate
    { id: "s4", x: 48, y: 76, answer: "ossuric"  }, // bottom: terminus
  ],
  // curve paths between slots — described as SVG paths (source % space 0..100)
  channels: [
    { from: "s1", to: "s2", type: "pulse" },
    { from: "s1", to: "s3", type: "pulse" },
    { from: "s2", to: "s4", type: "fluid" },
    { from: "s3", to: "s4", type: "fluid" },
  ],
  inventory: ["vordex", "thrennic", "valdris", "ossuric"],
};

// ---- App ------------------------------------------------------------------

const { useState, useEffect, useMemo, useRef, useCallback } = React;

function useTweaks() {
  const [tweaks, setTweaks] = useState(window.__TWEAKS__ || {
    forcedOutcome: "auto",         // auto | success | organ_fail | structural_fail
    organTreatment: "placeholder", // placeholder | geometric | illustrated
    showTweaksPanel: false,
  });
  useEffect(() => {
    const onMsg = (e) => {
      const d = e.data || {};
      if (d.type === "__activate_edit_mode")   setTweaks(t => ({...t, showTweaksPanel: true}));
      if (d.type === "__deactivate_edit_mode") setTweaks(t => ({...t, showTweaksPanel: false}));
    };
    window.addEventListener("message", onMsg);
    window.parent.postMessage({type: "__edit_mode_available"}, "*");
    return () => window.removeEventListener("message", onMsg);
  }, []);
  const update = (patch) => {
    setTweaks(t => ({...t, ...patch}));
    const persistable = {...patch};
    delete persistable.showTweaksPanel;
    if (Object.keys(persistable).length) {
      window.parent.postMessage({type: "__edit_mode_set_keys", edits: persistable}, "*");
    }
  };
  return [tweaks, update];
}

function App() {
  const [tweaks, setTweaks] = useTweaks();
  const [placements, setPlacements] = useState({}); // slotId -> organKey
  const [selected, setSelected] = useState(null);   // organKey selected from inventory
  const [attempts, setAttempts] = useState(0);
  const [phase, setPhase] = useState("idle");       // idle | running | success | organ_fail | structural_fail | solved
  const [failedSlots, setFailedSlots] = useState(new Set());
  const [flowOn, setFlowOn] = useState(false);      // toggles channel flow animation during run

  const placedCount = Object.keys(placements).length;
  const allPlaced = placedCount === PUZZLE.slots.length;
  const canRun = allPlaced && phase === "idle";

  // organs still available in inventory (not yet placed)
  const availableInventory = useMemo(() => {
    const placedSet = new Set(Object.values(placements));
    return PUZZLE.inventory.map(k => ({ key: k, placed: placedSet.has(k) }));
  }, [placements]);

  const onOrganTap = (key, placed) => {
    if (phase !== "idle") return;
    if (placed) return;
    setSelected(prev => prev === key ? null : key);
  };

  const onSlotTap = (slotId) => {
    if (phase !== "idle") return;
    // If slot occupied, tapping it clears it back to inventory
    if (placements[slotId]) {
      const next = {...placements}; delete next[slotId];
      setPlacements(next); setSelected(null); return;
    }
    if (!selected) return;
    setPlacements(p => ({...p, [slotId]: selected}));
    setSelected(null);
  };

  const runSimulation = () => {
    if (!canRun) return;
    setAttempts(a => a + 1);
    setPhase("running");
    setFlowOn(true);

    // determine outcome
    const wrongSlots = PUZZLE.slots.filter(s => placements[s.id] !== s.answer).map(s => s.id);
    let outcome;
    if (tweaks.forcedOutcome !== "auto") {
      outcome = tweaks.forcedOutcome;
    } else if (wrongSlots.length === 0) {
      outcome = "success";
    } else if (wrongSlots.length >= 3) {
      outcome = "structural_fail"; // many things wrong at once
    } else {
      outcome = "organ_fail";
    }

    // if forced organ_fail but everything's correct, invent a "bad" set
    const badForDisplay = outcome === "success" ? new Set() :
      outcome === "structural_fail" ? new Set(PUZZLE.slots.map(s => s.id)) :
      new Set(wrongSlots.length ? wrongSlots : [PUZZLE.slots[0].id, PUZZLE.slots[2].id]);

    // run sim "diagnostic" for 900ms then reveal
    setTimeout(() => {
      setFlowOn(false);
      setFailedSlots(badForDisplay);
      if (outcome === "success") {
        setPhase("success");
        setTimeout(() => setPhase("solved"), 2000);
      } else if (outcome === "organ_fail") {
        setPhase("organ_fail");
        setTimeout(() => { setPhase("idle"); setFailedSlots(new Set()); }, 1800);
      } else {
        setPhase("structural_fail");
        setTimeout(() => { setPhase("idle"); setFailedSlots(new Set()); }, 2800);
      }
    }, 900);
  };

  const resetPuzzle = () => {
    setPlacements({}); setSelected(null); setPhase("idle"); setFailedSlots(new Set()); setFlowOn(false);
  };

  const continueNext = () => {
    // For the demo we just reset
    resetPuzzle(); setAttempts(0);
  };

  return (
    <div className="app">
      <Header />
      <Stage
        tweaks={tweaks}
        placements={placements}
        selected={selected}
        phase={phase}
        failedSlots={failedSlots}
        flowOn={flowOn}
        attempts={attempts}
        availableInventory={availableInventory}
        onOrganTap={onOrganTap}
        onSlotTap={onSlotTap}
        runSimulation={runSimulation}
        canRun={canRun}
        resetPuzzle={resetPuzzle}
        continueNext={continueNext}
      />
      <SideNotes attempts={attempts} phase={phase} placements={placements} />
      {tweaks.showTweaksPanel && <TweaksPanel tweaks={tweaks} setTweaks={setTweaks} />}
    </div>
  );
}

// ---- Header ---------------------------------------------------------------

function Header() {
  return (
    <header className="app-header">
      <div className="brandmark">
        <svg width="22" height="22" viewBox="0 0 22 22" aria-hidden="true">
          <circle cx="11" cy="11" r="9.5" fill="none" stroke="currentColor" strokeWidth="0.8"/>
          <circle cx="11" cy="11" r="5" fill="none" stroke="currentColor" strokeWidth="0.8"/>
          <circle cx="11" cy="11" r="1.6" fill="currentColor"/>
          <line x1="11" y1="0.5" x2="11" y2="3.5" stroke="currentColor" strokeWidth="0.8"/>
          <line x1="11" y1="18.5" x2="11" y2="21.5" stroke="currentColor" strokeWidth="0.8"/>
          <line x1="0.5" y1="11" x2="3.5" y2="11" stroke="currentColor" strokeWidth="0.8"/>
          <line x1="18.5" y1="11" x2="21.5" y2="11" stroke="currentColor" strokeWidth="0.8"/>
        </svg>
        <div className="brand-type">
          <div className="brand-name">Specimen</div>
          <div className="brand-meta">XENOBIOLOGICAL REPAIR LOG · 04.2026</div>
        </div>
      </div>
      <div className="header-meta">
        <div className="meta-block">
          <div className="meta-label">STATION</div>
          <div className="meta-val">KEPLER-442b · ORBITAL</div>
        </div>
        <div className="meta-block">
          <div className="meta-label">ANALYST</div>
          <div className="meta-val">DR. HALE, I.</div>
        </div>
        <div className="meta-block">
          <div className="meta-label">CASE</div>
          <div className="meta-val">04 / 147</div>
        </div>
      </div>
    </header>
  );
}

// ---- Stage: phone frame + chamber -----------------------------------------

function Stage(props) {
  const {
    tweaks, placements, selected, phase, failedSlots, flowOn, attempts,
    availableInventory, onOrganTap, onSlotTap, runSimulation, canRun, resetPuzzle, continueNext
  } = props;

  return (
    <main className="stage">
      <LeftRail attempts={attempts} placements={placements} phase={phase} />

      <div className="device-wrap">
        <div className="device-caption">
          <span className="caps">fig. 04</span>
          <span> · live specimen viewer </span>
          <span className="caps" style={{color:"var(--ink-tertiary)"}}>480 × 854 portrait</span>
        </div>
        <Device>
          <PuzzleScreen
            tweaks={tweaks}
            placements={placements}
            selected={selected}
            phase={phase}
            failedSlots={failedSlots}
            flowOn={flowOn}
            attempts={attempts}
            availableInventory={availableInventory}
            onOrganTap={onOrganTap}
            onSlotTap={onSlotTap}
            runSimulation={runSimulation}
            canRun={canRun}
            continueNext={continueNext}
          />
        </Device>
        <div className="device-actions">
          <button className="btn-ghost" onClick={resetPuzzle}>↺ Reset specimen</button>
          <Autosolve onSet={(map) => {
            // used by the instructor button: prefill correct answers minus one
            resetPuzzle();
            Object.entries(map).forEach(([k,v]) => placements[k] = v);
          }} />
        </div>
      </div>

      <RightRail phase={phase} tweaks={tweaks} />
    </main>
  );
}

function Autosolve({ onSet }) {
  return null; // not used in UI, placeholder for future instructor helper
}

// ---- Device frame (portrait) ---------------------------------------------

function Device({ children }) {
  return (
    <div className="device">
      <div className="device-notch">
        <div className="notch-speaker"/>
        <div className="notch-cam"/>
      </div>
      <div className="device-screen">{children}</div>
      <div className="device-home"/>
    </div>
  );
}

// ---- The actual puzzle screen (lives inside the phone) --------------------

function PuzzleScreen(props) {
  const {
    tweaks, placements, selected, phase, failedSlots, flowOn, attempts,
    availableInventory, onOrganTap, onSlotTap, runSimulation, canRun, continueNext
  } = props;

  const chamberClass = [
    "chamber",
    phase === "success" ? "chamber--success" : "",
    phase === "organ_fail" ? "chamber--organ-fail" : "",
    phase === "structural_fail" ? "chamber--structural" : "",
    phase === "solved" ? "chamber--solved" : "",
  ].join(" ");

  return (
    <div className="screen">
      {/* top bar */}
      <div className="screen-topbar">
        <div className="topbar-title">
          <div className="tt-kicker">SPECIMEN</div>
          <div className="tt-name">Vorrkai <span className="tt-var">· var. IV</span></div>
        </div>
        <div className="topbar-attempts">
          <div className="att-kicker">ATTEMPT</div>
          <div className="att-n">{String(Math.min(attempts, 99)).padStart(2,'0')}{attempts > 99 ? '+' : ''}</div>
        </div>
      </div>

      {/* chamber = specimen viewer */}
      <div className={chamberClass}>
        <ChamberChrome />
        <CreatureSVG
          tweaks={tweaks}
          placements={placements}
          selected={selected}
          phase={phase}
          failedSlots={failedSlots}
          flowOn={flowOn}
          onSlotTap={onSlotTap}
        />
        {phase === "structural_fail" && <StructuralOverlay />}
        {phase === "success" && <SuccessGlow />}
        <DiagnosticReadout phase={phase} attempts={attempts} placements={placements} />
      </div>

      {/* HUD */}
      <div className="screen-hud">
        <div className="hud-kicker">
          <span>INVENTORY</span>
          <span className="hud-kicker-r">{Object.keys(placements).length}/4 INSTALLED</span>
        </div>
        <div className="hud-grid">
          {availableInventory.map(({key, placed}) => (
            <OrganCard
              key={key}
              organKey={key}
              selected={selected === key}
              placed={placed}
              treatment={tweaks.organTreatment}
              disabled={phase !== "idle"}
              onTap={() => onOrganTap(key, placed)}
            />
          ))}
        </div>

        {/* RUN button + result area */}
        {phase === "solved" ? (
          <div className="hud-result hud-result--ok">
            <div className="result-line"><span className="tick">✓</span> Specimen repaired</div>
            <button className="btn-continue" onClick={continueNext}>CONTINUE →</button>
          </div>
        ) : (
          <>
            <button
              className={"btn-run " + (canRun ? "" : "btn-run--locked")}
              onClick={runSimulation}
              disabled={!canRun}
            >
              <span className="run-icon">▶</span>
              <span className="run-label">RUN SIMULATION</span>
              <span className="run-tail">{canRun ? "[ ENTER ]" : "[ LOCKED ]"}</span>
            </button>

            <div className="hud-result">
              {phase === "idle" && <span className="result-line result-line--muted">Awaiting operator input…</span>}
              {phase === "running" && <span className="result-line"><span className="blink">◉</span> Running diagnostic…</span>}
              {phase === "organ_fail" && <span className="result-line result-line--bad">✗ Organ misfit — rejection detected</span>}
              {phase === "structural_fail" && <span className="result-line result-line--bad">✗ System failure — cascade offline</span>}
              {phase === "success" && <span className="result-line result-line--ok"><span className="tick">✓</span> Vitals rising…</span>}
            </div>
          </>
        )}
      </div>
    </div>
  );
}

// ---- Diagnostic readout (bottom of chamber) -------------------------------

function DiagnosticReadout({ phase, attempts, placements }) {
  const bpm = phase === "success" ? 74 : phase === "running" ? "---" : 0;
  const pulse = phase === "success" ? "STABLE" : phase === "running" ? "SCAN" : phase === "organ_fail" ? "REJECT" : phase === "structural_fail" ? "OFFLINE" : "DORMANT";
  return (
    <div className="diag-readout">
      <div className="diag-cell"><span className="diag-k">BPM</span><span className="diag-v">{bpm}</span></div>
      <div className="diag-cell"><span className="diag-k">STATE</span><span className="diag-v">{pulse}</span></div>
      <div className="diag-cell"><span className="diag-k">SLOTS</span><span className="diag-v">{Object.keys(placements).length}/4</span></div>
      <div className="diag-cell"><span className="diag-k">ATT</span><span className="diag-v">{String(Math.min(attempts,99)).padStart(2,'0')}</span></div>
    </div>
  );
}

// ---- Overlays -------------------------------------------------------------

function StructuralOverlay() {
  return (
    <div className="structural-overlay">
      <div className="so-text">
        <div className="so-l1">STRUCTURAL</div>
        <div className="so-l2">FAILURE</div>
        <div className="so-l3">// SUBJECT COHERENCE LOST</div>
      </div>
    </div>
  );
}

function SuccessGlow() {
  return <div className="success-glow" />;
}

// ---- Chamber chrome (rulers, corners, labels) -----------------------------

function ChamberChrome() {
  return (
    <>
      <div className="chamber-grid" />
      <div className="chamber-corner chamber-corner--tl" />
      <div className="chamber-corner chamber-corner--tr" />
      <div className="chamber-corner chamber-corner--bl" />
      <div className="chamber-corner chamber-corner--br" />
      <div className="chamber-label chamber-label--tl">OBS-04</div>
      <div className="chamber-label chamber-label--tr">37.2°C · 1.0atm</div>
      <div className="chamber-label chamber-label--br">x1.0 · LIVE</div>
      <div className="chamber-rule chamber-rule--left">
        {Array.from({length: 8}).map((_, i) => <span key={i} style={{top: `${(i+1) * 11}%`}}>{(i+1)*10}</span>)}
      </div>
    </>
  );
}

// ---- Creature SVG (silhouette + channels + slots) -------------------------

function CreatureSVG({ tweaks, placements, selected, phase, failedSlots, flowOn, onSlotTap }) {
  const width = 400;
  const height = 380;
  const slotToXY = (s) => ({ cx: (s.x/100)*width, cy: (s.y/100)*height });

  // build curved paths
  const channels = PUZZLE.channels.map(ch => {
    const a = PUZZLE.slots.find(s => s.id === ch.from);
    const b = PUZZLE.slots.find(s => s.id === ch.to);
    const p1 = slotToXY(a); const p2 = slotToXY(b);
    // bezier control towards creature center-ish
    const mx = (p1.cx + p2.cx) / 2;
    const my = (p1.cy + p2.cy) / 2;
    const dx = p2.cx - p1.cx, dy = p2.cy - p1.cy;
    // perpendicular offset for organic curve
    const off = 38 * (ch.type === "fluid" ? 1 : -1);
    const len = Math.hypot(dx, dy) || 1;
    const nx = -dy/len * off, ny = dx/len * off;
    const c1 = { x: mx + nx, y: my + ny };
    const d = `M ${p1.cx} ${p1.cy} Q ${c1.x} ${c1.y} ${p2.cx} ${p2.cy}`;
    return { ...ch, d, p1, p2 };
  });

  const chamberGlow = phase === "success" ? "rgba(0,255,136,0.28)" :
                      phase === "organ_fail" ? "rgba(255,51,51,0.18)" :
                      phase === "structural_fail" ? "rgba(170,68,255,0.22)" :
                      "rgba(74,184,255,0.08)";

  return (
    <svg className="creature-svg" viewBox={`0 0 ${width} ${height}`} preserveAspectRatio="xMidYMid meet">
      <defs>
        <radialGradient id="chamberGlow" cx="50%" cy="45%" r="55%">
          <stop offset="0%"  stopColor={chamberGlow} />
          <stop offset="100%" stopColor="rgba(0,0,0,0)" />
        </radialGradient>
        <filter id="softGlow" x="-50%" y="-50%" width="200%" height="200%">
          <feGaussianBlur stdDeviation="3.2" result="b"/>
          <feMerge><feMergeNode in="b"/><feMergeNode in="SourceGraphic"/></feMerge>
        </filter>
        <pattern id="xhatch" patternUnits="userSpaceOnUse" width="6" height="6" patternTransform="rotate(45)">
          <line x1="0" y1="0" x2="0" y2="6" stroke="rgba(184,154,106,0.28)" strokeWidth="0.6"/>
        </pattern>
      </defs>

      {/* chamber radial */}
      <rect x="0" y="0" width={width} height={height} fill="url(#chamberGlow)" />

      {/* creature silhouette — annotated wireframe style */}
      <CreatureSilhouette width={width} height={height} phase={phase} />

      {/* channels */}
      {channels.map((ch, i) => {
        const aPlaced = !!placements[ch.from];
        const bPlaced = !!placements[ch.to];
        const active = aPlaced && bPlaced;
        const stroke = ch.type === "pulse" ? "var(--channel-pulse)" : "var(--channel-fluid)";
        const w = ch.type === "pulse" ? 1.6 : 3.4;
        const dashW = ch.type === "pulse" ? "3 5" : "6 9";
        const isSuccess = phase === "success";
        const isBad = phase === "organ_fail" || phase === "structural_fail";
        return (
          <g key={i} className="channel">
            {/* base dim path */}
            <path d={ch.d} fill="none"
              stroke={stroke} strokeWidth={w}
              strokeOpacity={active ? 0.35 : 0.12}
              strokeLinecap="round" />
            {/* flow dashes */}
            {active && (
              <path d={ch.d} fill="none"
                stroke={isSuccess ? "var(--bio-green)" : isBad ? "var(--organ-red)" : stroke}
                strokeWidth={w + 0.6}
                strokeLinecap="round"
                strokeDasharray={dashW}
                className={flowOn || isSuccess ? "channel-flow channel-flow--on" : "channel-flow"}
                style={{filter: active && (flowOn || isSuccess) ? "url(#softGlow)" : undefined}}
              />
            )}
            {/* channel-type tag at midpoint */}
            <ChannelTag ch={ch} />
          </g>
        );
      })}

      {/* slots */}
      {PUZZLE.slots.map((s) => {
        const {cx, cy} = slotToXY(s);
        const placed = placements[s.id];
        const isFailed = failedSlots.has(s.id);
        const isSelected = placed && selected === placed;
        return (
          <Slot
            key={s.id} s={s} cx={cx} cy={cy}
            organKey={placed}
            isFailed={isFailed}
            phase={phase}
            treatment={tweaks.organTreatment}
            highlighted={!placed && selected != null}
            onTap={() => onSlotTap(s.id)}
          />
        );
      })}
    </svg>
  );
}

function ChannelTag({ ch }) {
  // midpoint of the bezier approximation
  const mx = (ch.p1.cx + ch.p2.cx)/2;
  const my = (ch.p1.cy + ch.p2.cy)/2;
  const label = ch.type === "pulse" ? "PULSE" : "FLUID";
  const color = ch.type === "pulse" ? "var(--channel-pulse)" : "var(--channel-fluid)";
  return (
    <g transform={`translate(${mx} ${my})`} opacity="0.8">
      <rect x="-18" y="-7" width="36" height="12" rx="2" fill="var(--bg-chamber)" stroke={color} strokeOpacity="0.5" strokeWidth="0.6"/>
      <text x="0" y="2" textAnchor="middle" fontFamily="JetBrains Mono, monospace" fontSize="7" fill={color} style={{letterSpacing: "0.16em"}}>{label}</text>
    </g>
  );
}

// ---- Creature silhouette --------------------------------------------------

function CreatureSilhouette({ width, height, phase }) {
  // A symmetrical blueprint creature: central body, four limb-nodes approx at our slot positions,
  // with annotation callouts & a numbered figure ref.
  const dim = phase === "structural_fail" ? 0.35 : 0.7;
  return (
    <g className="creature" opacity={dim}>
      {/* outer aura */}
      <ellipse cx={width*0.5} cy={height*0.48} rx={width*0.36} ry={height*0.40}
        fill="url(#xhatch)" opacity="0.6" />
      {/* body outline — organic blob */}
      <path
        d={`
          M ${width*0.5} ${height*0.10}
          C ${width*0.72} ${height*0.14}, ${width*0.84} ${height*0.34}, ${width*0.78} ${height*0.52}
          C ${width*0.86} ${height*0.64}, ${width*0.74} ${height*0.82}, ${width*0.58} ${height*0.86}
          C ${width*0.56} ${height*0.95}, ${width*0.44} ${height*0.95}, ${width*0.42} ${height*0.86}
          C ${width*0.26} ${height*0.82}, ${width*0.14} ${height*0.64}, ${width*0.22} ${height*0.52}
          C ${width*0.16} ${height*0.34}, ${width*0.28} ${height*0.14}, ${width*0.5} ${height*0.10}
          Z
        `}
        fill="none"
        stroke="var(--plate-bone)"
        strokeOpacity="0.55"
        strokeWidth="0.9"
        strokeDasharray="0"
      />
      {/* inner structural lines */}
      <path d={`M ${width*0.5} ${height*0.10} L ${width*0.5} ${height*0.95}`} stroke="var(--plate-bone)" strokeOpacity="0.14" strokeWidth="0.5" strokeDasharray="2 3"/>
      <path d={`M ${width*0.14} ${height*0.48} L ${width*0.86} ${height*0.48}`} stroke="var(--plate-bone)" strokeOpacity="0.14" strokeWidth="0.5" strokeDasharray="2 3"/>
      {/* annotation — top */}
      <g transform={`translate(${width*0.5}, ${height*0.06})`} fontFamily="JetBrains Mono, monospace" fontSize="7" fill="var(--plate-brass)">
        <text textAnchor="middle" style={{letterSpacing:"0.18em"}}>VORRKAI · FIG. 04</text>
      </g>
      {/* tiny cells around body to add life */}
      {[0.3, 0.7].map((ax, i) => (
        <g key={i} opacity="0.5">
          <circle cx={width*ax} cy={height*0.32} r="1.2" fill="var(--plate-bone)"/>
          <circle cx={width*ax} cy={height*0.64} r="1.2" fill="var(--plate-bone)"/>
        </g>
      ))}
    </g>
  );
}

// ---- Slot (SVG element) ---------------------------------------------------

function Slot({ s, cx, cy, organKey, isFailed, phase, treatment, highlighted, onTap }) {
  const type = organKey ? ORGAN_TYPES[organKey] : null;
  const color = type ? type.color : "var(--ink-quaternary)";
  const size = 64; // visual slot
  const isSuccess = phase === "success";
  const isOrganFail = phase === "organ_fail";
  const ringColor = isFailed && isOrganFail ? "var(--organ-red)" :
                    isSuccess ? "var(--bio-green)" :
                    highlighted ? "var(--slot-yellow)" :
                    organKey ? color :
                    "var(--ink-quaternary)";
  const ringOpacity = organKey ? 0.85 : highlighted ? 1 : 0.4;
  const flashClass = isFailed && isOrganFail ? "slot--failing" : "";

  return (
    <g transform={`translate(${cx} ${cy})`} className={`slot ${flashClass}`} onClick={onTap} style={{cursor:"pointer"}}>
      {/* tap target */}
      <rect x={-size/2 - 6} y={-size/2 - 6} width={size+12} height={size+12} fill="transparent"/>
      {/* corner brackets (always) */}
      <SlotBrackets size={size} color={ringColor} opacity={ringOpacity} />
      {/* filled content */}
      {!organKey && (
        <g>
          <rect x={-size/2} y={-size/2} width={size} height={size} rx="6"
            fill="rgba(10,14,18,0.6)"
            stroke={highlighted ? "var(--slot-yellow)" : "var(--ink-quaternary)"}
            strokeOpacity={highlighted ? 0.9 : 0.35}
            strokeWidth={highlighted ? 1.2 : 0.8}
            strokeDasharray={highlighted ? "4 3" : "2 3"}
          />
          <text y="-2" textAnchor="middle" fontFamily="JetBrains Mono, monospace" fontSize="7.5"
            fill="var(--ink-tertiary)" style={{letterSpacing:"0.18em"}}>SLOT</text>
          <text y="10" textAnchor="middle" fontFamily="JetBrains Mono, monospace" fontSize="10"
            fill="var(--plate-bone)" opacity="0.7">{s.id.toUpperCase()}</text>
        </g>
      )}
      {organKey && (
        <OrganGlyph key={organKey + treatment} organKey={organKey} size={size} treatment={treatment} healthy={!isFailed && !isOrganFail && phase !== "structural_fail"} phase={phase}/>
      )}
      {/* selected highlight ring */}
      {highlighted && (
        <rect x={-size/2 - 4} y={-size/2 - 4} width={size+8} height={size+8} rx="8"
          fill="none" stroke="var(--slot-yellow)" strokeWidth="1.2" strokeDasharray="5 4" className="highlight-ring"/>
      )}
      {/* slot id label under */}
      <text y={size/2 + 14} textAnchor="middle" fontFamily="JetBrains Mono, monospace" fontSize="7"
        fill="var(--ink-tertiary)" style={{letterSpacing:"0.18em"}}>
        {organKey ? ORGAN_TYPES[organKey].short : `[ ${s.id.toUpperCase()} ]`}
      </text>
    </g>
  );
}

function SlotBrackets({ size, color, opacity }) {
  const s = size/2 + 4;
  const len = 8;
  const stroke = color;
  const w = 1.3;
  const paths = [
    `M ${-s} ${-s+len} L ${-s} ${-s} L ${-s+len} ${-s}`,
    `M ${s-len} ${-s} L ${s} ${-s} L ${s} ${-s+len}`,
    `M ${-s} ${s-len} L ${-s} ${s} L ${-s+len} ${s}`,
    `M ${s-len} ${s} L ${s} ${s} L ${s} ${s-len}`,
  ];
  return (
    <g opacity={opacity}>
      {paths.map((d, i) => <path key={i} d={d} stroke={stroke} strokeWidth={w} fill="none" strokeLinecap="square"/>)}
    </g>
  );
}

// ---- Organ glyph (3 visual treatments) ------------------------------------

function OrganGlyph({ organKey, size, treatment, healthy, phase }) {
  const type = ORGAN_TYPES[organKey];
  const color = type.color;
  const s = size - 8;
  const opacity = healthy ? 1 : 0.55;
  return (
    <g className={"organ " + (healthy ? "organ--healthy" : "organ--damaged")} style={{transformOrigin:"center"}}>
      {/* common background plate */}
      <rect x={-s/2} y={-s/2} width={s} height={s} rx="5"
        fill="rgba(10,14,18,0.85)"
        stroke={color} strokeOpacity="0.6" strokeWidth="0.9"/>
      {treatment === "placeholder" && <OrganPlaceholder type={type} size={s} opacity={opacity}/>}
      {treatment === "geometric" && <OrganGeometric type={type} size={s} opacity={opacity}/>}
      {treatment === "illustrated" && <OrganIllustrated type={type} size={s} opacity={opacity}/>}
      {/* health tick */}
      <circle cx={s/2 - 6} cy={-s/2 + 6} r="2"
        fill={healthy ? "var(--bio-green)" : "var(--organ-red)"}
        opacity={phase === "running" ? 0 : 0.9}/>
    </g>
  );
}

function OrganPlaceholder({ type, size, opacity }) {
  // monospace caption only — honest about being a placeholder
  return (
    <g opacity={opacity}>
      <text y="-5" textAnchor="middle" fontFamily="JetBrains Mono, monospace" fontSize="8.2"
        fill={type.color} style={{letterSpacing:"0.18em"}}>{type.short}</text>
      <text y="6" textAnchor="middle" fontFamily="JetBrains Mono, monospace" fontSize="5.5"
        fill="var(--ink-secondary)" style={{letterSpacing:"0.14em"}}>[ASSET]</text>
      <text y="14" textAnchor="middle" fontFamily="JetBrains Mono, monospace" fontSize="5.5"
        fill="var(--ink-tertiary)" style={{letterSpacing:"0.14em"}}>PENDING</text>
    </g>
  );
}

function OrganGeometric({ type, size, opacity }) {
  // a shape per functional role
  const s = size;
  const color = type.color;
  const common = { fill: "none", stroke: color, strokeWidth: 1.4, opacity };
  return (
    <g opacity={opacity}>
      {type.role === "source" && (
        <>
          <circle r={s*0.26} {...common}/>
          <circle r={s*0.10} fill={color}/>
          {[0,60,120,180,240,300].map(deg => {
            const rad = deg * Math.PI/180;
            const x1 = Math.cos(rad)*s*0.30, y1 = Math.sin(rad)*s*0.30;
            const x2 = Math.cos(rad)*s*0.40, y2 = Math.sin(rad)*s*0.40;
            return <line key={deg} x1={x1} y1={y1} x2={x2} y2={y2} {...common}/>;
          })}
        </>
      )}
      {type.role === "gate" && (
        <>
          <rect x={-s*0.30} y={-s*0.22} width={s*0.60} height={s*0.44} rx="2" {...common}/>
          <line x1={-s*0.30} y1="0" x2={s*0.30} y2="0" {...common}/>
          <circle cx={-s*0.30} cy="0" r={s*0.06} fill={color}/>
          <circle cx={s*0.30} cy="0" r={s*0.06} fill={color}/>
        </>
      )}
      {type.role === "splitter" && (
        <>
          <circle r={s*0.08} fill={color}/>
          <line x1="0" y1="0" x2={-s*0.30} y2={-s*0.22} {...common}/>
          <line x1="0" y1="0" x2={-s*0.30} y2={s*0.22} {...common}/>
          <line x1="0" y1="0" x2={s*0.30} y2="0" {...common}/>
          <circle cx={-s*0.30} cy={-s*0.22} r={s*0.05} fill={color}/>
          <circle cx={-s*0.30} cy={s*0.22} r={s*0.05} fill={color}/>
          <circle cx={s*0.30} cy="0" r={s*0.05} fill={color}/>
        </>
      )}
      {type.role === "sink" && (
        <>
          <circle r={s*0.30} {...common} strokeDasharray="3 2"/>
          <circle r={s*0.18} {...common}/>
          <circle r={s*0.06} fill={color}/>
        </>
      )}
    </g>
  );
}

function OrganIllustrated({ type, size, opacity }) {
  // Slightly more ornate but still placeholder-grade; labeled & minimal.
  const s = size;
  const color = type.color;
  return (
    <g opacity={opacity}>
      <OrganGeometric type={type} size={s} opacity={1}/>
      <text y={s*0.44} textAnchor="middle" fontFamily="JetBrains Mono, monospace" fontSize="5.5"
        fill={color} style={{letterSpacing:"0.18em"}}>{type.short}</text>
    </g>
  );
}

// ---- Inventory card -------------------------------------------------------

function OrganCard({ organKey, selected, placed, disabled, treatment, onTap }) {
  const type = ORGAN_TYPES[organKey];
  const cls = [
    "organ-card",
    selected ? "organ-card--selected" : "",
    placed ? "organ-card--placed" : "",
    disabled ? "organ-card--disabled" : "",
  ].join(" ");
  return (
    <button className={cls} onClick={onTap} disabled={disabled || placed}>
      <div className="oc-thumb">
        <svg viewBox="-40 -40 80 80" width="56" height="56">
          <OrganGlyph organKey={organKey} size={64} treatment={treatment} healthy={true} phase="idle" />
        </svg>
        {placed && <div className="oc-installed">INSTALLED</div>}
      </div>
      <div className="oc-body">
        <div className="oc-name">{type.name}</div>
        <div className="oc-meta">
          <span className="oc-swatch" style={{background: type.color}} />
          <span className="oc-role">{type.role.toUpperCase()}</span>
          <span className="oc-short">· {type.short}</span>
        </div>
        <div className="oc-desc">{type.desc}</div>
      </div>
    </button>
  );
}

// ---- Side rails (context, not in the game but on the lab bench) -----------

function LeftRail({ attempts, placements, phase }) {
  const lines = [
    { t: "15:04:02", m: "Session opened — operator ID verified" },
    { t: "15:04:18", m: "Specimen VORRKAI-IV retrieved from cryochamber 04" },
    { t: "15:05:11", m: "Vitals baseline: FLATLINE — awaiting reconstitution" },
    { t: "15:05:47", m: "Diagnostic channels armed (PULSE, FLUID)" },
  ];
  if (attempts > 0) lines.push({ t: "15:07:21", m: `Attempt ${attempts} submitted — ${phase === 'success' || phase === 'solved' ? 'viable' : phase === 'idle' ? 'reset' : 'pending'}` });
  return (
    <aside className="rail rail--left">
      <div className="rail-head">
        <div className="rail-kicker">// SESSION LOG</div>
        <div className="rail-title">Field Notebook <span className="rail-sub">vol. 04</span></div>
      </div>
      <div className="notes">
        {lines.map((l, i) => (
          <div key={i} className="note">
            <span className="note-t">{l.t}</span>
            <span className="note-m">{l.m}</span>
          </div>
        ))}
      </div>

      <div className="rail-head" style={{marginTop:28}}>
        <div className="rail-kicker">// OBSERVED</div>
        <div className="rail-title">Hypotheses</div>
      </div>
      <ol className="hypos">
        <li>Central <em>emitter</em> drives both flanks via PULSE — if absent, silence.</li>
        <li><em>Splitter</em> expected left; it duplicates a signal into two paths.</li>
        <li><em>Gate</em> expected right; it admits only paired inputs.</li>
        <li>All FLUID flows must reach a <em>terminus</em>, or cavitation.</li>
      </ol>
    </aside>
  );
}

function RightRail({ phase, tweaks }) {
  return (
    <aside className="rail rail--right">
      <div className="rail-head">
        <div className="rail-kicker">// LEGEND</div>
        <div className="rail-title">Channel dictionary</div>
      </div>
      <div className="legend">
        <div className="legend-row">
          <span className="legend-swatch" style={{background:"var(--channel-pulse)", height: 2}}/>
          <div><strong>PULSE</strong> bioelectric — fast, precise, thin</div>
        </div>
        <div className="legend-row">
          <span className="legend-swatch" style={{background:"var(--channel-fluid)", height: 4}}/>
          <div><strong>FLUID</strong> organic — slow, viscous, broad</div>
        </div>
      </div>

      <div className="rail-head" style={{marginTop:28}}>
        <div className="rail-kicker">// OUTCOMES</div>
        <div className="rail-title">What the creature will tell you</div>
      </div>
      <ul className="outcomes">
        <li>
          <span className="dot" style={{background:"var(--bio-green)"}}/>
          <span><strong>Revival.</strong> A cascading glow from center, 4 slots blooming in sequence.</span>
        </li>
        <li>
          <span className="dot" style={{background:"var(--organ-red)"}}/>
          <span><strong>Organ rejection.</strong> Only the offending slots flash, three times.</span>
        </li>
        <li>
          <span className="dot" style={{background:"var(--structural-purple)"}}/>
          <span><strong>Structural failure.</strong> Screen dims; whole system bleeds violet.</span>
        </li>
      </ul>

      <div className="rail-foot">
        <div className="rail-kicker">// PROTOTYPE NOTE</div>
        <p>No tutorial, no kill-screen text, no hand-holding. The creature is the interface. Everything the player learns is inferred from how the specimen responds.</p>
      </div>
    </aside>
  );
}

function SideNotes({ attempts, phase, placements }) { return null; }

// ---- Tweaks panel ---------------------------------------------------------

function TweaksPanel({ tweaks, setTweaks }) {
  const OutcomeOptions = [
    { v:"auto", l:"Auto (based on placements)"},
    { v:"success", l:"Force success"},
    { v:"organ_fail", l:"Force organ failure"},
    { v:"structural_fail", l:"Force structural collapse"},
  ];
  const OrganOptions = [
    { v:"placeholder", l:"Placeholder (labeled)"},
    { v:"geometric", l:"Geometric stand-in"},
    { v:"illustrated", l:"Illustrated (stylized)"},
  ];
  return (
    <div className="tweaks-panel">
      <div className="tp-head">
        <span className="caps">Tweaks</span>
        <span className="tp-sub">live controls</span>
      </div>
      <div className="tp-group">
        <div className="tp-label">Simulation outcome</div>
        {OutcomeOptions.map(o => (
          <label key={o.v} className={"tp-radio " + (tweaks.forcedOutcome === o.v ? "on":"")}>
            <input type="radio" name="outcome" checked={tweaks.forcedOutcome === o.v}
              onChange={() => setTweaks({forcedOutcome: o.v})}/>
            {o.l}
          </label>
        ))}
        <div className="tp-hint">Run Simulation to see the sequence. "Auto" uses the real answer key.</div>
      </div>
      <div className="tp-group">
        <div className="tp-label">Organ visual treatment</div>
        {OrganOptions.map(o => (
          <label key={o.v} className={"tp-radio " + (tweaks.organTreatment === o.v ? "on":"")}>
            <input type="radio" name="organ" checked={tweaks.organTreatment === o.v}
              onChange={() => setTweaks({organTreatment: o.v})}/>
            {o.l}
          </label>
        ))}
        <div className="tp-hint">Placeholder is the honest default — agency delivers finals.</div>
      </div>
    </div>
  );
}

// Export to window
window.SpecimenApp = App;
ReactDOM.createRoot(document.getElementById("root")).render(<App />);
