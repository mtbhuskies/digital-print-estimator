import React, { useMemo, useState, useEffect, useRef, createContext, useContext } from "react";

/* ---------------- UI tokens ---------------- */
const TOK = {
  card: "bg-white rounded-[var(--radius)] shadow-sm border border-stone-200",
  header: "px-6 py-4 border-b bg-white flex items-center justify-between sticky top-0 z-30",
  btn: "inline-flex items-center justify-center rounded-[10px] h-9 px-3 text-sm transition",
  btnPri: "bg-indigo-600 text-white hover:bg-indigo-700",
  btnSec: "bg-stone-800 text-white hover:bg-stone-900",
  btnDanger: "bg-rose-600 text-white hover:bg-rose-700",
  btnGhost: "bg-white hover:bg-stone-50 border border-stone-300",
  h2: "text-[13px] font-semibold text-stone-800",
  label: "text-[12px] font-medium text-stone-700",
  help: "text-[11px] text-stone-500",
  chip: "rounded-lg border px-3 py-2 text-left",
  secTitle: "text-[12px] font-semibold text-stone-700",
  subTitle: "text-[11px] text-stone-500",
  stack: "space-y-4"
};

/* ---------------- Mini router ---------------- */
function useHashRoute() {
  const [path, setPath] = useState(location.hash.replace(/^#/, "") || "/job");
  useEffect(() => {
    const onHash = () => setPath(location.hash.replace(/^#/, "") || "/job");
    window.addEventListener("hashchange", onHash);
    return () => window.removeEventListener("hashchange", onHash);
  }, []);
  return [path, (p)=>{ location.hash = p; }];
}

/* ---------------- Defaults (for first run / seeding) ---------------- */
const DEFAULT_DEVICE = {
  setupMinutes: 6,
  runSpeedIPH: 2400,
  overheadPerHour: 28.0,
  wastePctDefault: 0.02, // 2% scrap by default
};
const DEFAULT_CLICK_RATES = {
  color: 0.07, // $ per color impression
  bw:    0.03, // $ per B/W impression
};
/* include Staple, Pad, Round corner by default */
const DEFAULT_FINISHING = [
  { id: "TRIM",   name: "Trim to size", setupMinutes: 2, costPerUnit: 0.01 },
  { id: "SCORE",  name: "Score/Fold",   setupMinutes: 4, costPerUnit: 0.03 },
  { id: "STAPLE", name: "Staple",       setupMinutes: 1, costPerUnit: 0.005 },
  { id: "PAD",    name: "Pad",          setupMinutes: 3, costPerUnit: 0.020 },
  { id: "ROUND",  name: "Round corner", setupMinutes: 2, costPerUnit: 0.015 },
];
const DEFAULT_GLOBAL = { defaultMarginPct: 0.5 };

const SUBSTRATES = [
  { sku: "SMOOTH-120C", name: "Smooth White 120# Cover", size: { wMM: 330, hMM: 482 }, costPerPack: 145.0, unitsPerPack: 200, wasteFixedSheets: 10, wastePct: 0.025, costPerSheet: 145.0 / 200 },
  { sku: "TEXT-100",   name: "Text 100#",               size: { wMM: 330, hMM: 482 }, costPerPack: 82.0,  unitsPerPack: 500, wasteFixedSheets: 8,  wastePct: 0.02,  costPerSheet: 82.0  / 500 },
];

/* ---------------- Utils ---------------- */
const roundToInc = (v, inc = 0.05) => Math.round(v / inc) * inc;
const clamp = (n, min, max) => Math.max(min, Math.min(max, n));
const money = (n) => n.toLocaleString(undefined, { style: "currency", currency: "USD" });
const IN_TO_MM = 25.4;
const inToMM = (inches) => inches * IN_TO_MM;
const mmToIn = (mm) => mm / IN_TO_MM;

/* ---------------- Storage: Inventory & Presets ---------------- */
const loadInventory = () => { try { return JSON.parse(localStorage.getItem("inventory")||"null")||[]; } catch { return []; } };
const saveInventory = (arr) => localStorage.setItem("inventory", JSON.stringify(arr));

const PRESETS_KEY = "presets_v1";
const DEFAULT_PRESETS = [
  { id: "BUS-CARD", name: "Business Cards", sizeIN: { w: 3.5, h: 2.0 }, sheetWIN: 13, sheetHIN: 19,
    sides: 2, colors: "4/4", defaultSubstrate: "SMOOTH-120C", defaultFinishing: ["TRIM"],
    qtyBreaks: [50, 100, 250, 500, 1000, 2500], defaultMarginPct: 0.55 },
  { id: "POSTCARD", name: "Postcards", sizeIN: { w: 6.0, h: 4.0 }, sheetWIN: 13, sheetHIN: 19,
    sides: 2, colors: "4/4", defaultSubstrate: "SMOOTH-120C", defaultFinishing: ["TRIM"],
    qtyBreaks: [50, 100, 250, 500, 1000], defaultMarginPct: 0.50 },
  { id: "FLYER",    name: "Flyers", sizeIN: { w: 8.5, h: 11.0 }, sheetWIN: 13, sheetHIN: 19,
    sides: 2, colors: "4/4", defaultSubstrate: "TEXT-100", defaultFinishing: [],
    qtyBreaks: [50, 100, 250, 500, 1000], defaultMarginPct: 0.48 },
];
function loadPresetsLS(){
  try {
    const v = JSON.parse(localStorage.getItem(PRESETS_KEY)||"null");
    if (Array.isArray(v) && v.length) return v;
  } catch {}
  localStorage.setItem(PRESETS_KEY, JSON.stringify(DEFAULT_PRESETS));
  return DEFAULT_PRESETS;
}
function savePresetsLS(p){ localStorage.setItem(PRESETS_KEY, JSON.stringify(p)); }

/* ---------------- Storage: Pricing ---------------- */
const PRICING_KEY = "pricing_v1";
function loadPricing(){
  try {
    const v = JSON.parse(localStorage.getItem(PRICING_KEY)||"null");
    if (v && v.device && v.clickRates && v.finishing && v.global) {
      // Merge in any missing finishing steps by ID (non-destructive)
      const present = new Set(v.finishing.map(f=>f.id));
      DEFAULT_FINISHING.forEach(df => { if (!present.has(df.id)) v.finishing.push(df); });
      return v;
    }
  } catch {}
  const seed = { device: DEFAULT_DEVICE, clickRates: DEFAULT_CLICK_RATES, finishing: DEFAULT_FINISHING, global: DEFAULT_GLOBAL };
  localStorage.setItem(PRICING_KEY, JSON.stringify(seed));
  return seed;
}
function savePricing(p){ localStorage.setItem(PRICING_KEY, JSON.stringify(p)); }

/* ---------------- Storage: Quotes ---------------- */
const QUOTES_KEY = "quotes_v1";
function loadQuotes(){ try { return JSON.parse(localStorage.getItem(QUOTES_KEY)||"null")||[]; } catch { return []; } }
function saveQuotes(list){ localStorage.setItem(QUOTES_KEY, JSON.stringify(list)); }
function newId(){ return (crypto?.randomUUID?.() || Math.random().toString(36).slice(2)) }

/* ---------------- Pricing Context ---------------- */
const PricingCtx = createContext(null);
const usePricing = () => useContext(PricingCtx);

/* ---------------- Parsers & helpers ---------------- */
function parseSizeInches(sizeStr){
  if(!sizeStr) return null;
  const m = String(sizeStr).replace(/[^0-9.xX]/g,'').match(/(\d+(?:\.\d+)?)[xX](\d+(?:\.\d+)?)/);
  if(!m) return null;
  const w = parseFloat(m[1]), h = parseFloat(m[2]);
  if(Number.isNaN(w)||Number.isNaN(h)) return null;
  return { w, h };
}
function findSubstrateFallback(sku){
  return SUBSTRATES.find(s=>s.sku===sku) || SUBSTRATES[0];
}
function effectiveSheetSizeMM(line){
  const invList = loadInventory();
  const inv = invList.find(x=>x.sku===line.substrateSku);
  const invSz = inv ? parseSizeInches(inv.size) : null;
  const fallback = findSubstrateFallback(line.substrateSku).size;

  const hasOverride = (line.sheetWOverrideIN||0) > 0 && (line.sheetHOverrideIN||0) > 0;
  if(hasOverride) return { wMM: inToMM(line.sheetWOverrideIN), hMM: inToMM(line.sheetHOverrideIN) };
  if(invSz) return { wMM: inToMM(invSz.w), hMM: inToMM(invSz.h) };
  return fallback;
}

function colorBwSidesFromColorsLabel(label){
  switch(label){
    case "4/4": return { colorSides: 2, bwSides: 0, sides: 2 };
    case "4/1": return { colorSides: 1, bwSides: 1, sides: 2 };
    case "4/0": return { colorSides: 1, bwSides: 0, sides: 1 };
    case "1/1": return { colorSides: 0, bwSides: 2, sides: 2 };
    case "1/0": return { colorSides: 0, bwSides: 1, sides: 1 };
    default:    return { colorSides: 2, bwSides: 0, sides: 2 };
  }
}

/* ---------------- Layout computation ---------------- */
function computeLayout({
  sheetW, sheetH,
  pieceWmm, pieceHmm,
  bleedMM, gutterMM,
  allowRotate = true,
  manualCols = 0,
  manualRows = 0,
}) {
  const effW = pieceWmm + 2 * bleedMM;
  const effH = pieceHmm + 2 * bleedMM;

  const gridBest = (w, h) => {
    const cols = Math.max(0, Math.floor((sheetW + gutterMM) / (w + gutterMM)));
    const rows = Math.max(0, Math.floor((sheetH + gutterMM) / (h + gutterMM)));
    const ups = cols * rows;
    const usedW = cols * w + Math.max(0, cols - 1) * gutterMM;
    const usedH = rows * h + Math.max(0, rows - 1) * gutterMM;
    const offX = Math.max(0, (sheetW - usedW) / 2);
    const offY = Math.max(0, (sheetH - usedH) / 2);
    return { cols, rows, ups, w, h, offX, offY, fits: true, rot: 0 };
  };

  const gridManual = (w, h, cols, rows) => {
    cols = Math.max(0, Math.floor(cols || 0));
    rows = Math.max(0, Math.floor(rows || 0));
    const ups = cols * rows;
    const usedW = cols * w + Math.max(0, cols - 1) * gutterMM;
    const usedH = rows * h + Math.max(0, rows - 1) * gutterMM;
    const fits = usedW <= sheetW && usedH <= sheetH && cols > 0 && rows > 0;
    const offX = Math.max(0, (sheetW - usedW) / 2);
    const offY = Math.max(0, (sheetH - usedH) / 2);
    return { cols, rows, ups, w, h, offX, offY, fits };
  };

  if (manualCols > 0 && manualRows > 0) {
    const M0 = gridManual(effW, effH, manualCols, manualRows);
    const candidates = [{ ...M0, rot: 0 }];
    if (allowRotate) {
      const M90 = gridManual(effH, effW, manualCols, manualRows);
      candidates.push({ ...M90, rot: 90 });
    }
    const chosen = candidates.find(c => c.fits) || candidates[0];
    const cells = [];
    for (let r = 0; r < chosen.rows; r++) {
      for (let c = 0; c < chosen.cols; c++) {
        const x = chosen.offX + c * (chosen.w + gutterMM);
        const y = chosen.offY + r * (chosen.h + gutterMM);
        cells.push({ x, y, w: chosen.w, h: chosen.h });
      }
    }
    return { ...chosen, cells };
  }

  const A = gridBest(effW, effH);
  const B = allowRotate ? gridBest(effH, effW) : { ups: -1, fits: false, rot: 90 };
  const best = A.ups >= B.ups ? A : B;
  const cells = [];
  for (let r = 0; r < best.rows; r++) {
    for (let c = 0; c < best.cols; c++) {
      const x = best.offX + c * (best.w + gutterMM);
      const y = best.offY + r * (best.h + gutterMM);
      cells.push({ x, y, w: best.w, h: best.h });
    }
  }
  return { ...best, cells };
}

function autoColsRowsFor(line){
  const sheet = effectiveSheetSizeMM(line);
  const layout = computeLayout({
    sheetW: sheet.wMM, sheetH: sheet.hMM,
    pieceWmm: inToMM(line.sizeIN.w), pieceHmm: inToMM(line.sizeIN.h),
    bleedMM: inToMM(line.bleedIN||0), gutterMM: inToMM(line.gutterIN||0),
    allowRotate: line.allowRotate!==false,
    manualCols: 0, manualRows: 0,
  });
  return { cols: layout.cols||0, rows: layout.rows||0 };
}

/* ---------------- Cost calc per line (uses pricing) ---------------- */
function computeLineCosts(line, pricing) {
  const { device, clickRates, finishing } = pricing;
  const substrate = findSubstrateFallback(line.substrateSku);
  const sheetMM = effectiveSheetSizeMM(line);

  const layout = computeLayout({
    sheetW: sheetMM.wMM, sheetH: sheetMM.hMM,
    pieceWmm: inToMM(line.sizeIN.w), pieceHmm: inToMM(line.sizeIN.h),
    bleedMM: inToMM(line.bleedIN||0),
    gutterMM: inToMM(line.gutterIN||0),
    allowRotate: line.allowRotate!==false,
    manualCols: Number(line.manualCols)||0,
    manualRows: Number(line.manualRows)||0,
  });

  const up = Math.max(1, layout.ups || 1);

  // Waste & sheets
  const wasteUnits = Math.ceil(line.qty * (device.wastePctDefault ?? 0.02));
  const effectiveQty = line.qty + wasteUnits;
  const sheets = Math.ceil(effectiveQty / up);

  // Sides mapping from "Sides/Colors"
  const colorsLabel = line.colors || "4/4";
  const { colorSides, bwSides, sides } = colorBwSidesFromColorsLabel(colorsLabel);

  // Clicks (fixed rates)
  const clicksColor = sheets * colorSides;
  const clicksBW    = sheets * bwSides;
  const clicks      = sheets * sides;

  const clickRateColor = clickRates?.color ?? 0.07;
  const clickRateBW    = clickRates?.bw    ?? 0.03;
  const clicksCost     = (clicksColor * clickRateColor) + (clicksBW * clickRateBW);

  // Time/overhead
  const setupCost    = (device.setupMinutes / 60) * device.overheadPerHour;
  const runMinutes   = (clicks / device.runSpeedIPH) * 60;
  const overheadCost = (runMinutes / 60) * device.overheadPerHour;

  // Substrate
  const substrateCost = sheets * substrate.costPerSheet;

  // Finishing
  const finishingCost = (line.finishingStepIds||[]).reduce((sum, id) => {
    const step = finishing.find((f) => f.id === id);
    if (!step) return sum;
    return sum + (step.setupMinutes / 60) * device.overheadPerHour + step.costPerUnit * line.qty;
  }, 0);

  const baseCost = setupCost + overheadCost + clicksCost + substrateCost + finishingCost;
  const sell = roundToInc(baseCost * (1 + clamp(line.marginPct ?? pricing.global.defaultMarginPct, 0, 2)));

  return { up, sheets, clicks, clicksCost, substrateCost, setupCost, overheadCost, finishingCost, baseCost, sell };
}

function useContainerWidth(){
  const ref = useRef(null);
  const [,setW]=useState(0);
  useEffect(()=>{
    if(!ref.current) return;
    const ro=new ResizeObserver(entries=>{
      for(const e of entries){ setW(Math.floor(e.contentRect.width)); }
    });
    ro.observe(ref.current);
    return ()=>ro.disconnect();
  },[]);
  return [ref];
}

/* ---------------- Diagram ---------------- */
function LayoutDiagram({ line, showMetrics = true }){
  const [wrapRef] = useContainerWidth();

  const CHIP_W = 88, CHIP_G = 8;
  const RAIL_W = CHIP_W * 2 + CHIP_G;
  const OUTER_H = 220;

  const sheet = effectiveSheetSizeMM(line);
  const sheetWmm = sheet.wMM, sheetHmm = sheet.hMM;
  const pieceWmm = inToMM(line.sizeIN.w);
  const pieceHmm = inToMM(line.sizeIN.h);
  const bleedMM  = inToMM(line.bleedIN||0);
  const gutterMM = inToMM(line.gutterIN||0);

  const layout = React.useMemo(()=>computeLayout({
    sheetW: sheetWmm, sheetH: sheetHmm,
    pieceWmm, pieceHmm, bleedMM, gutterMM,
    allowRotate: line.allowRotate!==false,
    manualCols: Number(line.manualCols)||0,
    manualRows: Number(line.manualRows)||0,
  }), [sheetWmm,sheetHmm,pieceWmm,pieceHmm,bleedMM,gutterMM,line.allowRotate,line.manualCols,line.manualRows]);

  const isLandscape = sheetWmm > sheetHmm;
  const dispWmm = isLandscape ? sheetHmm : sheetWmm;
  const dispHmm = isLandscape ? sheetWmm : sheetHmm;

  const PAD = 8, TOP_LABEL = 18, LEFT_LABEL = 20;
  const availWpx = RAIL_W - LEFT_LABEL - PAD;
  const availHpx = OUTER_H - TOP_LABEL - PAD*2;
  const scale = Math.min(availWpx/Math.max(dispWmm,1), availHpx/Math.max(dispHmm,1));
  const toPx = (mm) => mm * scale;

  const sheetWpx = toPx(dispWmm);
  const sheetHpx = toPx(dispHmm);

  const svgW = RAIL_W, svgH = OUTER_H;
  const originX = LEFT_LABEL;
  const originY = TOP_LABEL + (svgH - TOP_LABEL - sheetHpx)/2;

  function physToDispRect(xMM, yMM, wMM, hMM){
    if(!isLandscape){
      return { x: toPx(xMM), y: toPx(yMM), w: toPx(wMM), h: toPx(hMM) };
    }
    const x2 = yMM;
    const y2 = sheetWmm - (xMM + wMM);
    return { x: toPx(x2), y: toPx(y2), w: toPx(hMM), h: toPx(wMM) };
  }
  const dispCells = layout.cells.map(c => physToDispRect(c.x, c.y, c.w, c.h));

  const sheets = Math.ceil((line.qty + Math.ceil(line.qty*0.02)) / Math.max(1, layout.ups || 1));
  const clicks  = sheets * (line.sides||1);

  const sheetArea = sheetWmm * sheetHmm;
  const usedArea  = (layout.cols||0) * (layout.rows||0) * (pieceWmm + 2*bleedMM) * (pieceHmm + 2*bleedMM)
                  + Math.max(0,(layout.cols-1)) * gutterMM * (layout.rows*(pieceHmm+2*bleedMM))
                  + Math.max(0,(layout.rows-1)) * gutterMM * (layout.cols*(pieceWmm+2*bleedMM));
  const wastePct  = sheetArea>0 ? Math.max(0, 1 - (usedArea / sheetArea)) * 100 : 0;

  const fmt1 = (inches) => (Math.round(inches * 10) / 10).toFixed(1);
  const topLabel  = fmt1(mmToIn(dispWmm));
  const leftLabel = fmt1(mmToIn(dispHmm));

  return (
    <div ref={wrapRef} className="mt-1">
      <div className="flex items-center justify-between">
        <div className="text-[12px] font-semibold text-stone-700">Layout Diagram</div>
        {(Number(line.manualCols)||0)>0 && (Number(line.manualRows)||0)>0 && (
          <div className={`text-[11px] ${layout.fits ? 'text-stone-500' : 'text-rose-600 font-semibold'}`}>
            {line.manualCols}×{line.manualRows} — {layout.ups||0} up {layout.fits ? '' : '(does not fit)'}
          </div>
        )}
      </div>

      <div className="mt-2 inline-block ml-auto p-2 bg-stone-50 border border-stone-200 rounded-lg overflow-hidden"
           style={{ width: RAIL_W }}>
        <svg style={{ width: RAIL_W, height: OUTER_H }} viewBox={`0 0 ${RAIL_W} ${OUTER_H}`} preserveAspectRatio="xMidYMid meet">
          <g transform={`translate(${originX},${originY})`}>
            <rect x={0} y={0} width={sheetWpx} height={sheetHpx} fill="#fff" stroke="#475569" strokeWidth="1"/>

            {/* Width callout (top) */}
            <line x1={0} y1={-8} x2={sheetWpx} y2={-8} stroke="#475569" strokeWidth="1" />
            <line x1={0} y1={-12} x2={0} y2={-2} stroke="#475569" strokeWidth="1" />
            <line x1={sheetWpx} y1={-12} x2={sheetWpx} y2={-2} stroke="#475569" strokeWidth="1" />
            <text x={sheetWpx/2} y={-16} textAnchor="middle" fontSize="11" fill="#334155">{topLabel}</text>

            {/* Height callout (left) */}
            <line x1={-8} y1={0} x2={-8} y2={sheetHpx} stroke="#475569" strokeWidth="1" />
            <line x1={-12} y1={0} x2={-2}  y2={0}              stroke="#475569" strokeWidth="1" />
            <line x1={-12} y1={sheetHpx} x2={-2} y2={sheetHpx} stroke="#475569" strokeWidth="1" />
            <text x={-16} y={sheetHpx/2} textAnchor="middle" dominantBaseline="middle"
                  transform={`rotate(-90, ${-16}, ${sheetHpx/2})`} fontSize="11" fill="#334155">{leftLabel}</text>

            {/* Cells */}
            {dispCells.map((cell,i)=>(
              <g key={i} transform={`translate(${cell.x},${cell.y})`}>
                <rect width={cell.w} height={cell.h} rx="4" ry="4" fill="#c7d2fe" stroke="#4338ca"/>
                <rect x="0" y="0" width={cell.w} height={toPx(bleedMM)} fill="#e2e8f0" />
                <rect x="0" y={cell.h-toPx(bleedMM)} width={cell.w} height={toPx(bleedMM)} fill="#e2e8f0" />
                <rect x="0" y="0" width={toPx(bleedMM)} height={cell.h} fill="#e2e8f0" />
                <rect x={cell.w-toPx(bleedMM)} y="0" width={toPx(bleedMM)} height={cell.h} fill="#e2e8f0" />
                <rect x={toPx(bleedMM)} y={toPx(bleedMM)}
                      width={cell.w-2*toPx(bleedMM)} height={cell.h-2*toPx(bleedMM)}
                      fill="#fff" stroke="#1f2937" strokeDasharray="4 3"/>
              </g>
            ))}
          </g>
        </svg>
      </div>

      {showMetrics && (
        <div className="mt-2 grid grid-cols-2 gap-2" style={{ width: RAIL_W }}>
          <div className="rounded-md border border-stone-300 bg-stone-50 px-2 py-1 flex justify-between text-[11px] text-stone-700" style={{ width: CHIP_W }}>
            <span>Ups</span><span className="font-semibold">{layout.ups||0}</span>
          </div>
          <div className="rounded-md border border-stone-300 bg-stone-50 px-2 py-1 flex justify-between text-[11px] text-stone-700" style={{ width: CHIP_W }}>
            <span>Sheets</span><span className="font-semibold">{Math.ceil((line.qty + Math.ceil(line.qty*0.02)) / Math.max(1, layout.ups || 1))}</span>
          </div>
          <div className="rounded-md border border-stone-300 bg-stone-50 px-2 py-1 flex justify-between text-[11px] text-stone-700" style={{ width: CHIP_W }}>
            <span>Clicks</span><span className="font-semibold">{Math.ceil((line.qty + Math.ceil(line.qty*0.02)) / Math.max(1, layout.ups || 1)) * (line.sides||1)}</span>
          </div>
          <div className="rounded-md border border-stone-300 bg-stone-50 px-2 py-1 flex justify-between text-[11px] text-stone-700" style={{ width: CHIP_W }}>
            <span>Waste</span><span className="font-semibold">{wastePct.toFixed(1)}%</span>
          </div>
        </div>
      )}
    </div>
  );
}

/* ---------------- Small UI primitives ---------------- */
function Field({ label, hint, children }){
  return (
    <label className="block">
      <div className="flex items-center gap-2">
        <div className={TOK.label}>{label}</div>
        {hint && <div className={TOK.help}>{hint}</div>}
      </div>
      <div className="mt-1">{children}</div>
    </label>
  );
}
function Input({
  value, onChange,
  type="text", placeholder, prefix, suffix, inputMode,
  nudgeStep, nudgeParser = (v)=>Number(v)||0,
  ...rest
}){
  const base = "h-field w-full pad-v rounded-md border text-sm px-3 transition outline-none";
  const state = "border-stone-300 focus:ring-2 focus:ring-indigo-300 focus:border-indigo-500";

  const handleKeyDown = (e)=>{
    if(!nudgeStep) return;
    if(e.key !== "ArrowUp" && e.key !== "ArrowDown") return;
    e.preventDefault();
    const cur = nudgeParser(e.currentTarget.value);
    const next = cur + (e.key === "ArrowUp" ? +nudgeStep : -nudgeStep);
    onChange && onChange({ target: { value: String(next) }});
  };

  return (
    <div className="relative">
      {prefix && <div className="absolute left-3 top-1/2 -translate-y-1/2 text-[12px] text-stone-500">{prefix}</div>}
      <input
        className={`${base} ${state} ${prefix?'pl-7':'pl-3'} ${suffix?'pr-9':'pr-3'}`}
        value={value}
        onChange={onChange}
        onKeyDown={handleKeyDown}
        type={type}
        placeholder={placeholder}
        inputMode={inputMode}
        {...rest}
      />
      {suffix && <div className="absolute right-3 top-1/2 -translate-y-1/2 text-[12px] text-stone-500">{suffix}</div>}
    </div>
  );
}
const Select = (p) => <select {...p} className="h-field w-full rounded-md border text-sm pl-3 pr-8 transition outline-none focus:ring-2 focus:ring-indigo-300 focus:border-indigo-500 border-stone-300 bg-white" />;

function Section({ title, subtitle, actions, children }){
  return (
    <div className="border rounded-md p-3">
      <div className="flex items-baseline justify-between">
        <div className={TOK.secTitle}>{title}</div>
        <div className="flex items-center gap-2">{actions}</div>
      </div>
      {subtitle && <div className="mt-1">{typeof subtitle==='string'?<div className={TOK.subTitle}>{subtitle}</div>:subtitle}</div>}
      <div className="mt-2">{children}</div>
    </div>
  );
}

/* ---------------- Inventory Page ---------------- */
function InventoryPage(){
  const [rows,setRows]=useState(()=>loadInventory());
  const [tmp,setTmp]=useState({ sku:"", name:"", size:"", onHand:0, reorderAt:0 });
  function add(){
    if(!tmp.sku || !tmp.name) return;
    const next=[...rows, {...tmp, onHand:Number(tmp.onHand)||0, reorderAt:Number(tmp.reorderAt)||0 }];
    setRows(next); saveInventory(next); setTmp({ sku:"", name:"", size:"", onHand:0, reorderAt:0 });
  }
  function del(sku){ const next=rows.filter(r=>r.sku!==sku); setRows(next); saveInventory(next); }
  function update(sku, patch){ const next=rows.map(r=>r.sku===sku?{...r, ...patch}:r); setRows(next); saveInventory(next); }
  return (
    <div className="mx-auto max-w-6xl md:pl-20 px-4 md:px-8 space-y-3">
      <div className="text-lg font-semibold">Paper Inventory</div>
      <div className={`${TOK.card} p-4 space-y-3`}>
        <div className="grid grid-cols-12 gap-2">
          <div className="col-span-2"><Field label="SKU"><Input value={tmp.sku} onChange={(e)=>setTmp({...tmp, sku:e.target.value})}/></Field></div>
          <div className="col-span-4"><Field label="Name"><Input value={tmp.name} onChange={(e)=>setTmp({...tmp, name:e.target.value})}/></Field></div>
          <div className="col-span-2"><Field label="Size"><Input value={tmp.size} onChange={(e)=>setTmp({...tmp, size:e.target.value})} placeholder='e.g. 13x19 in'/></Field></div>
          <div className="col-span-2"><Field label="On hand"><Input inputMode="numeric" value={tmp.onHand} onChange={(e)=>setTmp({...tmp, onHand:e.target.value})}/></Field></div>
          <div className="col-span-2"><Field label="Reorder at"><Input inputMode="numeric" value={tmp.reorderAt} onChange={(e)=>setTmp({...tmp, reorderAt:e.target.value})}/></Field></div>
        </div>
        <div><button className={`${TOK.btn} ${TOK.btnPri}`} onClick={add}>Add stock</button></div>
        <div className="overflow-auto border rounded-md">
          <table className="min-w-full text-sm">
            <thead className="bg-stone-50">
              <tr>
                <th className="px-3 py-2 text-left">SKU</th>
                <th className="px-3 py-2 text-left">Name</th>
                <th className="px-3 py-2 text-left">Size</th>
                <th className="px-3 py-2 text-right">On hand</th>
                <th className="px-3 py-2 text-right">Reorder at</th>
                <th className="px-3 py-2 text-right">Actions</th>
              </tr>
            </thead>
            <tbody>
              {rows.map(r=>{
                const low = r.onHand <= r.reorderAt;
                return (
                  <tr key={r.sku} className="border-t">
                    <td className="px-3 py-2">{r.sku}</td>
                    <td className="px-3 py-2">{r.name}</td>
                    <td className="px-3 py-2">{r.size}</td>
                    <td className={`px-3 py-2 text-right ${low?'text-rose-600 font-semibold':''}`}>{r.onHand}</td>
                    <td className="px-3 py-2 text-right">{r.reorderAt}</td>
                    <td className="px-3 py-2 text-right">
                      <button className={`${TOK.btn} ${TOK.btnGhost} mr-2`} onClick={()=>update(r.sku, { onHand: Number(r.onHand)+500 })}>+500</button>
                      <button className={`${TOK.btn} ${TOK.btnDanger}`} onClick={()=>del(r.sku)}>Delete</button>
                    </td>
                  </tr>
                );
              })}
            </tbody>
          </table>
        </div>
      </div>
    </div>
  );
}

/* ---------------- Sidebar / Top Tabs ---------------- */
function Sidebar({ route, goto }){
  const Item = ({slug,label}) => (
    <button
      onClick={()=>goto(slug)}
      className={`w-full text-center px-2 py-3 rounded-lg transition ${route===slug?'bg-fuchsia-700 text-white shadow-sm':'text-fuchsia-50/95 hover:bg-fuchsia-700/60'}`}>
      <div className="mx-auto w-6 h-6 rounded-md bg-white/30" />
      <div className="text-[11px] mt-1 leading-none">{label}</div>
    </button>
  );
  return (
    <aside className="hidden md:flex fixed left-0 top-0 h-screen w-20 bg-fuchsia-600 z-40 flex-col items-center pt-16 gap-2">
      <Item slug="/customer" label="Customer"/>
      <Item slug="/job" label="Job"/>
      <Item slug="/presets" label="Presets"/>
      <Item slug="/pricing" label="Pricing"/>
      <Item slug="/quotes" label="Quotes"/>
      <Item slug="/inventory" label="Inventory"/>
    </aside>
  );
}
function TopTabs({ route, goto }){
  const item=(slug,label)=>(
    <button onClick={()=>goto(slug)} className={`px-3 py-2 rounded-md text-sm ${route===slug?'bg-fuchsia-700 text-white':'text-white/95 hover:bg-fuchsia-700/60'}`}>{label}</button>
  );
  return (
    <div className="md:hidden bg-fuchsia-600 px-3 py-2 sticky top-0 z-40 flex items-center gap-2">
      {item("/customer","Customer")}
      {item("/job","Job")}
      {item("/presets","Presets")}
      {item("/pricing","Pricing")}
      {item("/quotes","Quotes")}
      {item("/inventory","Inventory")}
    </div>
  );
}

/* ---------------- Job / Line Item ---------------- */
function LineCard({ line, onChange, onDuplicate, onDelete, presets, inventory }){
  const { pricing } = usePricing();
  const costs=useMemo(()=>computeLineCosts(line, pricing),[line, pricing]);
  const qtys=(presets.find(p=>p.id===line.presetId)?.qtyBreaks)||(presets[0]?.qtyBreaks)||[50,100,250,500,1000,2500];

  const nameRef = useRef(null);
  useEffect(()=>{ if(line.focusName && nameRef.current){ nameRef.current.focus(); nameRef.current.select(); onChange({...line, focusName:false}); } },[line.focusName]);
  const invalidQty = !Number.isFinite(line.qty) || line.qty<=0;
  const invalidSize = !line.sizeIN?.w || !line.sizeIN?.h || line.sizeIN.w<=0 || line.sizeIN.h<=0;
  const priceDisabled = invalidQty || invalidSize;

  function applyPreset(id){
    const p=presets.find(x=>x.id===id); if(!p) return;
    const inv=inventory.find(s=>s.sku=== (p.defaultSubstrate||line.substrateSku));
    const invSz=inv?parseSizeInches(inv.size):null;
    const fb = findSubstrateFallback(p.defaultSubstrate||line.substrateSku).size;
    const next = {
      ...line,
      presetId:id,
      name: line.name || p.name,
      sizeIN:{...p.sizeIN},
      sides:p.sides||line.sides,
      colors:p.colors||line.colors||"4/4",
      substrateSku:p.defaultSubstrate||line.substrateSku,
      sheetWOverrideIN: invSz?invSz.w:(p.sheetWIN||mmToIn(fb.wMM)),
      sheetHOverrideIN: invSz?invSz.h:(p.sheetHIN||mmToIn(fb.hMM)),
      marginPct:p.defaultMarginPct??line.marginPct,
      finishingStepIds:[...(p.defaultFinishing||[])],
      allowRotate: true,
      manualCols: 0, manualRows: 0,
    };
    onChange(next);
  }

  function changePaper(sku){
    const inv=inventory.find(s=>s.sku===sku);
    const invSz=inv?parseSizeInches(inv.size):null;
    const fb=findSubstrateFallback(sku).size;
    onChange({
      ...line,
      substrateSku: sku,
      sheetWOverrideIN: invSz?invSz.w:mmToIn(fb.wMM),
      sheetHOverrideIN: invSz?invSz.h:mmToIn(fb.hMM),
      manualCols: 0, manualRows: 0,
    });
  }

  const invPaper = inventory.find(s=>s.sku===line.substrateSku);
  const parsedInvSz = invPaper?parseSizeInches(invPaper.size):null;
  const effSheetWIn = line.sheetWOverrideIN || (parsedInvSz?parsedInvSz.w:mmToIn(findSubstrateFallback(line.substrateSku).size.wMM));
  const effSheetHIn = line.sheetHOverrideIN || (parsedInvSz?parsedInvSz.h:mmToIn(findSubstrateFallback(line.substrateSku).size.hMM));

  const colorOptions = [
    { label: "4/4", sides: 2 },
    { label: "4/1", sides: 2 },
    { label: "4/0", sides: 1 },
    { label: "1/1", sides: 2 },
    { label: "1/0", sides: 1 },
  ];
  const curColors = line.colors || "4/4";
  const curSides = colorOptions.find(o=>o.label===curColors)?.sides || (line.sides||2);

  /* ---- Finishing options + helpers ---- */
  const finishingOptions = [
    { id: "TRIM",   label: "Trim" },
    { id: "SCORE",  label: "Score/Fold" },
    { id: "STAPLE", label: "Staple" },
    { id: "PAD",    label: "Pad" },
    { id: "ROUND",  label: "Round corner" },
  ];
  const stepCostForQty = (stepId) => {
    const step = pricing.finishing.find(f => f.id === stepId);
    if (!step) return 0;
    const setup = (step.setupMinutes / 60) * pricing.device.overheadPerHour;
    const run   = (step.costPerUnit || 0) * (line.qty || 0);
    return setup + run;
  };
  const toggleFinishing = (stepId) => {
    const list = Array.isArray(line.finishingStepIds) ? line.finishingStepIds : [];
    const next = list.includes(stepId)
      ? list.filter(id => id !== stepId)
      : [...list, stepId];
    onChange({ ...line, finishingStepIds: next });
  };

  return (
    <div className={`${TOK.card} p-4 ${TOK.stack}`}>
      <Section
        title="Line item"
        actions={
          <div className="hidden md:flex gap-2">
            <button className={`${TOK.btn} ${TOK.btnSec}`} onClick={onDuplicate}>Duplicate</button>
            <button className={`${TOK.btn} ${TOK.btnDanger}`} onClick={onDelete}>Delete</button>
          </div>
        }
      >
        <div className="grid grid-cols-12 md:gap-3 gap-2 items-end">
          <div className="col-span-12 md:col-span-9">
            <Field label="Name">
              <input ref={nameRef} className="h-field w-full pad-v rounded-md border text-sm px-3 transition outline-none border-stone-300 focus:ring-2 focus:ring-indigo-300 focus:border-indigo-500"
                     value={line.name||""}
                     onChange={(e)=>onChange({...line, name:e.target.value})}
                     placeholder="e.g., Business Cards for Spring Promo"/>
            </Field>
          </div>
          <div className="col-span-12 md:col-span-3">
            <Field label="Qty">
              <Input inputMode="numeric" value={line.qty}
                     nudgeStep={25}
                     onChange={(e)=>onChange({...line, qty: Number(e.target.value)||0})}/>
              {(!Number.isFinite(line.qty)||line.qty<=0) && <div className="mt-1 text-[11px] text-rose-600">Enter a quantity &gt; 0</div>}
            </Field>
          </div>
        </div>
      </Section>

      <Section title="Layout">
        <div className="grid grid-cols-1 md:grid-cols-[1fr,auto] md:gap-4 gap-2 items-start">
          {/* Left controls */}
          <div className={`${TOK.stack}`}>
            {/* Preset + Sides/Colors */}
            <div className="grid grid-cols-12 gap-2 md:gap-3 items-end">
              {/* Preset wider */}
              <div className="col-span-12 lg:col-span-9">
                <Field label="Preset">
                  <Select
                    value={line.presetId || ""}
                    onChange={(e)=>applyPreset(e.target.value)}
                  >
                    <option value="" disabled>Select a preset…</option>
                    {presets.map(p=><option key={p.id} value={p.id}>{p.name}</option>)}
                  </Select>
                </Field>
              </div>
              {/* Sides/Colors narrower */}
              <div className="col-span-6 lg:col-span-2">
                <Field label="Sides/Colors">
                  <Select
                    value={line.colors || "4/4"}
                    onChange={(e)=>{
                      const sel = e.target.value;
                      const sides = [{label:"4/4",s:2},{label:"4/1",s:2},{label:"4/0",s:1},{label:"1/1",s:2},{label:"1/0",s:1}]
                        .find(o=>o.label===sel)?.s || 1;
                      onChange({ ...line, colors: sel, sides });
                    }}
                  >
                    {["4/4","4/1","4/0","1/1","1/0"].map(v=><option key={v} value={v}>{v}</option>)}
                  </Select>
                </Field>
              </div>
              {/* spacer to keep blank area on the right */}
              <div className="hidden lg:block lg:col-span-1" />
            </div>

            {/* 1) Paper - Sheet W - Sheet H */}
            <div className="grid grid-cols-12 gap-2 md:gap-3 items-end">
              <div className="col-span-12 md:col-span-6">
                <Field label="Paper (from Inventory)">
                  <Select value={line.substrateSku} onChange={(e)=>changePaper(e.target.value)}>
                    {inventory.map(s=><option key={s.sku} value={s.sku}>{s.name} ({s.sku})</option>)}
                  </Select>
                </Field>
              </div>
              <div className="col-span-6 md:col-span-3">
                <Field label="Sheet Width" hint="in">
                  <Input
                    type="number" step="any" inputMode="decimal"
                    value={Number(((line.sheetWOverrideIN)||(mmToIn(effectiveSheetSizeMM(line).wMM))).toFixed(3))}
                    nudgeStep={0.125} nudgeParser={(v)=>Number(v)||0}
                    onChange={(e)=>onChange({...line, sheetWOverrideIN: Number(e.target.value)||0, manualCols:0, manualRows:0})}
                    suffix="in"
                  />
                </Field>
              </div>
              <div className="col-span-6 md:col-span-3">
                <Field label="Sheet Height" hint="in">
                  <Input
                    type="number" step="any" inputMode="decimal"
                    value={Number(((line.sheetHOverrideIN)||(mmToIn(effectiveSheetSizeMM(line).hMM))).toFixed(3))}
                    nudgeStep={0.125} nudgeParser={(v)=>Number(v)||0}
                    onChange={(e)=>onChange({...line, sheetHOverrideIN: Number(e.target.value)||0, manualCols:0, manualRows:0})}
                    suffix="in"
                  />
                </Field>
              </div>
            </div>

            {/* 2) Width - Height - Bleed - Gutter */}
            <div className="grid grid-cols-12 gap-2 md:gap-3 items-end">
              <div className="col-span-6 md:col-span-3">
                <Field label="Width" hint="in">
                  <Input value={line.sizeIN.w}
                         nudgeStep={0.0625} nudgeParser={(v)=>Number(v)||0}
                         onChange={(e)=>onChange({...line, sizeIN:{...line.sizeIN, w:Number(e.target.value)||0}, manualCols:0, manualRows:0})}
                         suffix="in" inputMode="decimal"
                  />
                </Field>
              </div>
              <div className="col-span-6 md:col-span-3">
                <Field label="Height" hint="in">
                  <Input value={line.sizeIN.h}
                         nudgeStep={0.0625} nudgeParser={(v)=>Number(v)||0}
                         onChange={(e)=>onChange({...line, sizeIN:{...line.sizeIN, h:Number(e.target.value)||0}, manualCols:0, manualRows:0})}
                         suffix="in" inputMode="decimal"
                  />
                </Field>
              </div>
              <div className="col-span-6 md:col-span-3">
                <Field label="Bleed" hint="in">
                  <Input value={line.bleedIN||0.125}
                         nudgeStep={0.0625} nudgeParser={(v)=>Number(v)||0}
                         onChange={(e)=>onChange({...line, bleedIN:Number(e.target.value)||0, manualCols:0, manualRows:0})}
                         suffix="in" inputMode="decimal"
                  />
                </Field>
              </div>
              <div className="col-span-6 md:col-span-3">
                <Field label="Gutter" hint="in">
                  <Input value={line.gutterIN||0.125}
                         nudgeStep={0.0625} nudgeParser={(v)=>Number(v)||0}
                         onChange={(e)=>onChange({...line, gutterIN:Number(e.target.value)||0, manualCols:0, manualRows:0})}
                         suffix="in" inputMode="decimal"
                  />
                </Field>
              </div>
            </div>

            {/* 3) Columns - Rows */}
            <div className="grid grid-cols-12 gap-2 md:gap-3 items-end">
              <div className="col-span-6 md:col-span-3">
                <Field label="Columns (Across)">
                  <Input
                    type="number" inputMode="numeric" min={0}
                    value={Number(line.manualCols||0)}
                    nudgeStep={1} nudgeParser={(v)=>Number(v)||0}
                    onChange={(e)=>onChange({ ...line, manualCols: Math.max(0, Number(e.target.value)||0) })}
                  />
                </Field>
              </div>
              <div className="col-span-6 md:col-span-3">
                <Field label="Rows (Around)">
                  <Input
                    type="number" inputMode="numeric" min={0}
                    value={Number(line.manualRows||0)}
                    nudgeStep={1} nudgeParser={(v)=>Number(v)||0}
                    onChange={(e)=>onChange({ ...line, manualRows: Math.max(0, Number(e.target.value)||0) })}
                  />
                </Field>
              </div>
            </div>
          </div>

          {/* Right: diagram */}
          <div className="md:justify-self-end">
            <LayoutDiagram line={{...line, sides:curSides }} />
          </div>
        </div>
      </Section>

      {/* Finishing (per line) */}
      <Section title="Finishing">
        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-2">
          {finishingOptions.map(opt => {
            const checked = (line.finishingStepIds || []).includes(opt.id);
            const dollars = stepCostForQty(opt.id);
            return (
              <label key={opt.id}
                     className="flex items-center justify-between gap-3 rounded-md border border-stone-300 bg-white px-3 py-2 hover:bg-stone-50">
                <span className="flex items-center gap-2">
                  <input
                    type="checkbox"
                    className="h-4 w-4 rounded border-stone-300 text-indigo-600 focus:ring-indigo-500"
                    checked={!!checked}
                    onChange={() => toggleFinishing(opt.id)}
                  />
                  <span className="text-sm text-stone-800">{opt.label}</span>
                </span>
                <span className="text-[11px] px-2 py-1 rounded-md border bg-stone-50 text-stone-700">
                  {dollars > 0 ? dollars.toLocaleString(undefined, { style: "currency", currency: "USD" }) : "$0.00"}
                </span>
              </label>
            );
          })}
        </div>
        <div className="mt-2 text-[11px] text-stone-500">
          Chips show total cost of each selected step for this line’s current quantity (setup + per-unit).
        </div>
      </Section>

      {/* Pricing */}
      <Section title="Pricing" subtitle="Adjust margin, then pick a break">
        <div className="grid grid-cols-12 md:gap-3 gap-2 items-end">
          {/* spacer left to align */}
          <div className="col-span-0 md:col-span-9"></div>
          {/* NARROWER: Margin field now spans 3 columns */}
          <div className="col-span-12 md:col-span-3">
            <Field label="Margin %">
              <div className="flex items-center gap-2">
                <Input
                  type="number" step="0.1" inputMode="decimal"
                  value={Math.round((line.marginPct ?? 0.5)*100)}
                  nudgeStep={1}
                  onChange={(e)=>onChange({...line, marginPct: (Number(e.target.value)||0)/100})}
                  suffix="%"
                />
                <span className={`inline-flex items-center px-2 h-8 rounded-md border text-xs ${ ((line.marginPct ?? 0.5) < 0.35) ? 'border-rose-300 text-rose-700 bg-rose-50' : 'border-stone-300 text-stone-700 bg-stone-50'}`}>
                  {priceDisabled ? '—/ea' : `${money(costs.sell/(line.qty||1))}/ea`}
                </span>
              </div>
              {((line.marginPct ?? 0.5) < 0.35) && <div className="mt-1 text-[11px] text-rose-600">Below 35% margin</div>}
            </Field>
          </div>
        </div>

        <div className="mt-2">
          <div className={TOK.label}>Unit price by quantity</div>
          <div className="grid grid-cols-3 sm:grid-cols-4 md:grid-cols-5 lg:grid-cols-6 gap-2">
            {qtys.map(q=>{
              const preview = computeLineCosts({ ...line, sides:curSides, qty:q }, pricing);
              const unit = preview.sell / q;
              const active = q===line.qty;
              return (
                <button key={q} onClick={()=>onChange({...line, qty:q})}
                  className={`${TOK.chip} ${active?"bg-indigo-600 text-white border-indigo-600":"bg-white border-stone-300 hover:bg-stone-50"}`}>
                  <div className="text-[10px] opacity-80">{q} qty</div>
                  <div className="text-sm font-semibold">{money(unit)}</div>
                  <div className="text:[10px] text-[10px] opacity-80">{money(preview.sell)} total</div>
                </button>
              );
            })}
          </div>

          <details className="mt-3">
            <summary className="cursor-pointer text-sm text-stone-700">Cost breakdown</summary>
            {(() => { const c = computeLineCosts({ ...line, sides:curSides }, pricing); return (
              <div className="mt-2 grid grid-cols-2 gap-x-4 gap-y-1 text-[12px]">
                <div className="flex justify-between"><span>Substrate</span><span className="font-semibold">{money(c.substrateCost)}</span></div>
                <div className="flex justify-between"><span>Clicks</span><span className="font-semibold">{money(c.clicksCost)}</span></div>
                <div className="flex justify-between"><span>Setup</span><span className="font-semibold">{money(c.setupCost)}</span></div>
                <div className="flex justify-between"><span>Overhead</span><span className="font-semibold">{money(c.overheadCost)}</span></div>
                <div className="flex justify-between"><span>Finishing</span><span className="font-semibold">{money(c.finishingCost)}</span></div>
                <div className="flex justify-between border-t pt-1"><span>Base cost</span><span className="font-semibold">{money(c.baseCost)}</span></div>
                <div className="flex justify-between border-t pt-1"><span>Sell</span><span className="font-semibold">{money(c.sell)}</span></div>
                <div className="flex justify-between"><span>Unit price</span><span className="font-semibold">{money(c.sell/(line.qty||1))}</span></div>
              </div>
            ); })()}
          </details>
        </div>
      </Section>
    </div>
  );
}

/* ---------------- Job Page ---------------- */
function JobPage({ presets }){
  const { pricing } = usePricing();

  const [inventory]=useState(()=>{
    const inv=loadInventory();
    if(inv && inv.length) return inv;
    const seeded=[
      { sku:"SMOOTH-120C", name:"Smooth White 120# Cover", size:"13x19 in", onHand:1200, reorderAt:400 },
      { sku:"TEXT-100",    name:"Text 100#",               size:"13x19 in", onHand:4800, reorderAt:1000 }
    ];
    saveInventory(seeded);
    return seeded;
  });
  const [cust,setCust]=useState(()=>localStorage.getItem("job.customer")||"");
  const [jobTitle,setJobTitle]=useState(()=>localStorage.getItem("job.title")||"");
  const [taxPct,setTaxPct]=useState(()=>Number(localStorage.getItem("job.taxPct")||0));

  const [lines,setLines]=useState(()=>{
    const p=presets[0];
    const inv=loadInventory().find(x=>x.sku===p?.defaultSubstrate);
    const invSz = inv?parseSizeInches(inv.size):null;
    const fb = p ? findSubstrateFallback(p.defaultSubstrate||"SMOOTH-120C").size : SUBSTRATES[0].size;
    const base = {
      id: newId(),
      name: p? p.name : "Custom",
      qty: 250,
      presetId: p?.id || "",
      sizeIN: p? {...p.sizeIN} : { w: 4, h: 6 },
      sides: p?.sides || 2,
      colors: p?.colors || "4/4",
      substrateSku: p?.defaultSubstrate || "SMOOTH-120C",
      sheetWOverrideIN: invSz?invSz.w:(p?.sheetWIN || mmToIn(fb.wMM)),
      sheetHOverrideIN: invSz?invSz.h:(p?.sheetHIN || mmToIn(fb.hMM)),
      marginPct: p?.defaultMarginPct ?? DEFAULT_GLOBAL.defaultMarginPct,
      bleedIN: 0.125, gutterIN: 0.125,
      finishingStepIds: p?.defaultFinishing || [],
      allowRotate: true,
      manualCols: 0,
      manualRows: 0,
    };
    return [base];
  });

  const [lastQuoteId, setLastQuoteId] = useState(()=>localStorage.getItem("job.lastQuoteId")||"");
  useEffect(()=>{ if(lastQuoteId) localStorage.setItem("job.lastQuoteId", lastQuoteId); },[lastQuoteId]);

  function updateLine(id, patch){ setLines(prev=>prev.map(l=>l.id===id?{...l, ...patch}:l)); }

  const totals = React.useMemo(()=>lines.reduce((s,l)=>s+computeLineCosts(l, pricing).sell,0),[lines, pricing]);
  const grand  = useMemo(()=> totals * (1 + (Number(taxPct)||0)/100 ), [totals, taxPct]);

  function serializeJobToQuote(){
    const quoteLines = lines.map(l => {
      const costs = computeLineCosts(l, pricing);
      return {
        ...l,
        calc: {
          sell: costs.sell,
          baseCost: costs.baseCost,
          clicksCost: costs.clicksCost,
          overheadCost: costs.overheadCost,
          substrateCost: costs.substrateCost,
          finishingCost: costs.finishingCost,
          sheets: costs.sheets,
          clicks: costs.clicks,
          ups: costs.up
        }
      };
    });
    const subtotal = quoteLines.reduce((s, l) => s + (l.calc?.sell||0), 0);
    const total = subtotal * (1 + (Number(taxPct)||0)/100);
    return {
      id: lastQuoteId || newId(),
      customer: cust,
      title: jobTitle || "Untitled Quote",
      taxPct: Number(taxPct)||0,
      lines: quoteLines,
      subtotal,
      total,
      createdAt: lastQuoteId ? undefined : new Date().toISOString(),
      status: lastQuoteId ? undefined : "Sent",
      acceptedAt: undefined,
      acceptedBy: ""
    };
  }

  function createOrUpdateQuoteAndOpen(){
    const q = serializeJobToQuote();
    const all = loadQuotes();
    const idx = all.findIndex(x=>x.id===q.id);
    if(idx>=0){
      const merged = { ...all[idx], ...q };
      if(!all[idx].createdAt) merged.createdAt = new Date().toISOString();
      if(!all[idx].status) merged.status = "Sent";
      all[idx] = merged;
    }else{
      q.createdAt = new Date().toISOString();
      q.status = "Sent";
      all.push(q);
    }
    saveQuotes(all);
    setLastQuoteId(q.id);
    location.hash = `/quote/${q.id}`;
  }

  const lastQuoteStatus = (()=> {
    if(!lastQuoteId) return "";
    const q = loadQuotes().find(x=>x.id===lastQuoteId);
    return q?.status||"";
  })();

  const canConvertToJob = lastQuoteStatus === "Accepted";

  return (
    <div className="mx-auto max-w-7xl md:pl-20 px-4 md:px-8 grid grid-cols-1 lg:grid-cols-[1fr,18rem] gap-6 items-start">
      <div className={`${TOK.stack}`}>
        <div className={`${TOK.card} p-4`}>
          <div className="grid grid-cols-12 gap-2 md:gap-3">
            <div className="col-span-12 md:col-span-6">
              <Field label="Customer">
                <Input value={cust} onChange={(e)=>{ setCust(e.target.value); localStorage.setItem("job.customer", e.target.value); }}/>
              </Field>
            </div>
            <div className="col-span-12 md:col-span-6">
              <Field label="Job Title">
                <Input value={jobTitle} onChange={(e)=>{ setJobTitle(e.target.value); localStorage.setItem("job.title", e.target.value); }}/>
              </Field>
            </div>
          </div>
        </div>

        {lines.map(line=>(
          <LineCard key={line.id}
            line={line} presets={presets} inventory={loadInventory()}
            onChange={(patch)=>updateLine(line.id,patch)}
            onDuplicate={()=>setLines(prev=>[...prev,{...line,id:newId(), name: (line.name||'Copy')+' (copy)', focusName:true }])}
            onDelete={()=>setLines(prev=>prev.filter(l=>l.id!==line.id))}
          />
        ))}
        <div className="flex gap-2">
          <button className={`${TOK.btn} ${TOK.btnGhost}`} onClick={()=>{
            const p=presets[0];
            const inv=loadInventory().find(x=>x.sku===p?.defaultSubstrate);
            const invSz = inv?parseSizeInches(inv.size):null;
            const fb = p ? findSubstrateFallback(p.defaultSubstrate||"SMOOTH-120C").size : SUBSTRATES[0].size;
            const base = {
              id: newId(),
              name: p? p.name : "Custom",
              qty: 250,
              presetId: p?.id || "",
              sizeIN: p? {...p.sizeIN} : { w: 4, h: 6 },
              sides: p?.sides || 2,
              colors: p?.colors || "4/4",
              substrateSku: p?.defaultSubstrate || "SMOOTH-120C",
              sheetWOverrideIN: invSz?invSz.w:(p?.sheetWIN || mmToIn(fb.wMM)),
              sheetHOverrideIN: invSz?invSz.h:(p?.sheetHIN || mmToIn(fb.hMM)),
              marginPct: p?.defaultMarginPct ?? DEFAULT_GLOBAL.defaultMarginPct,
              bleedIN: 0.125, gutterIN: 0.125,
              finishingStepIds: p?.defaultFinishing || [],
              allowRotate: true,
              manualCols: 0,
              manualRows: 0,
            };
            setLines(prev=>[...prev, base]);
          }}>Add line</button>
        </div>
      </div>

      <aside className="sticky top-16 self-start">
        <div className="bg-white/95 backdrop-blur rounded-[var(--radius)] p-4 border border-stone-200 space-y-3 w-full lg:w-72">
          <div className={TOK.h2}>Totals</div>
          <div className="text-[13px] font-semibold text-stone-800">You’re quoting: <span className="text-indigo-700">{money(grand)}</span></div>
          <div className="flex items-center justify-between text-sm">
            <span>Tax %</span>
            <input className="h-8 w-20 rounded-md border text-sm px-2 border-stone-300 focus:ring-2 focus:ring-indigo-300 focus:border-indigo-500"
                   inputMode="decimal" value={taxPct}
                   onChange={(e)=>{ const v=Number(e.target.value)||0; setTaxPct(v); localStorage.setItem("job.taxPct", String(v)); }} />
          </div>
          <div className="flex justify-between text-sm"><span>Items</span><span>{money(totals)}</span></div>
          <div className="border-t pt-2 flex justify-between font-semibold"><span>Grand Total</span><span>{money(grand)}</span></div>

          {lastQuoteId && (
            <div className="text-[11px] text-stone-600 border-t pt-2">
              Last quote: <span className="font-medium">{lastQuoteId.slice(0,8)}</span> — <span className="font-medium">{lastQuoteStatus||"Draft"}</span>
            </div>
          )}

          <div className="mt-3 grid grid-cols-2 gap-2">
            <button className={`${TOK.btn} ${TOK.btnPri}`} onClick={createOrUpdateQuoteAndOpen}>Send / Preview</button>
            <button className={`${TOK.btn} ${TOK.btnSec}`} disabled={!canConvertToJob}
              title={canConvertToJob ? "Convert accepted quote to job" : "Enable by accepting the quote in Preview"}
              onClick={()=>{
                if(!canConvertToJob) return;
                alert("Converted to Job (stub). In a future step we’ll create a Job ticket record.");
              }}>
              Convert to Job
            </button>
          </div>
        </div>
      </aside>
    </div>
  );
}

/* ---------------- Customer Page (stub) ---------------- */
function CustomerPage(){
  return (
    <div className="mx-auto max-w-4xl md:pl-20 px-4 md:px-8">
      <div className="text-lg font-semibold">Customer</div>
      <div className={`${TOK.card} p-4 mt-2`}>Coming soon.</div>
    </div>
  );
}

/* ---------------- Presets Page ---------------- */
function PresetsPage({ presets, setPresets }){
  const [selectedId, setSelectedId] = useState(presets[0]?.id || "");
  const selected = presets.find(p=>p.id===selectedId) || null;

  const [local, setLocal] = useState(selected || null);
  useEffect(()=>{ setLocal(selected); }, [selectedId]);
  useEffect(()=>{ savePresetsLS(presets); }, [presets]);

  function updateLocal(k, v){ setLocal(prev=>prev?{...prev,[k]:v}:prev); }
  function save(){
    if(!local) return;
    setPresets(prev => prev.map(p => p.id===local.id ? local : p));
  }
  function remove(){
    if(!local) return;
    const idx = presets.findIndex(p=>p.id===local.id);
    const next = presets.filter(p=>p.id!==local.id);
    setPresets(next);
    setSelectedId(next[Math.max(0, idx-1)]?.id || "");
  }
  function addNew(){
    const id = `PRESET-${Math.random().toString(36).slice(2,8).toUpperCase()}`;
    const p = { id, name:"New Preset", sizeIN:{w:4,h:6}, sheetWIN:13, sheetHIN:19, sides:2, colors:"4/4", defaultSubstrate:"SMOOTH-120C", defaultFinishing:[], qtyBreaks:[50,100,250,500,1000], defaultMarginPct:0.5 };
    setPresets(prev=>[...prev, p]);
    setSelectedId(id);
  }

  // Preview controls state
  const [prevCols, setPrevCols] = useState(0);
  const [prevRows, setPrevRows] = useState(0);
  const [previewBleed, setPreviewBleed] = useState(0.125);
  const [previewGutter, setPreviewGutter] = useState(0.125);

  useEffect(()=>{
    if(local){
      const seedLine = {
        id: "preview",
        name: local.name,
        qty: 1000,
        presetId: local.id,
        sizeIN: {...local.sizeIN},
        sides: local.sides,
        colors: local.colors || "4/4",
        substrateSku: local.defaultSubstrate,
        sheetWOverrideIN: local.sheetWIN,
        sheetHOverrideIN: local.sheetHIN,
        marginPct: local.defaultMarginPct,
        bleedIN: previewBleed, gutterIN: previewGutter,
        finishingStepIds: [],
        allowRotate: true,
        manualCols: 0, manualRows: 0,
      };
      const ar = autoColsRowsFor(seedLine);
      setPrevCols(ar.cols); setPrevRows(ar.rows);
      setPreviewBleed(0.125);
      setPreviewGutter(0.125);
    }
  // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [selectedId, local?.sizeIN?.w, local?.sizeIN?.h, local?.sheetWIN, local?.sheetHIN]);

  const previewLine = local ? {
    id: "preview",
    name: local.name,
    qty: 1000,
    presetId: local.id,
    sizeIN: {...local.sizeIN},
    sides: local.sides,
    colors: local.colors || "4/4",
    substrateSku: local.defaultSubstrate,
    sheetWOverrideIN: local.sheetWIN,
    sheetHOverrideIN: local.sheetHIN,
    marginPct: local.defaultMarginPct,
    bleedIN: previewBleed,
    gutterIN: previewGutter,
    finishingStepIds: [],
    allowRotate: true,
    manualCols: Number(prevCols)||0,
    manualRows: Number(prevRows)||0,
  } : null;

  function changePresetPaper(sku){
    const inv = loadInventory().find(s=>s.sku===sku);
    const invSz = inv ? parseSizeInches(inv.size) : null;
    setLocal(prev => prev ? {
      ...prev,
      defaultSubstrate: sku,
      sheetWIN: invSz ? invSz.w : prev.sheetWIN,
      sheetHIN: invSz ? invSz.h : prev.sheetHIN,
    } : prev);
  }

  return (
    <div className="mx-auto max-w-7xl md:pl-20 px-4 md:px-8 grid grid-cols-1 lg:grid-cols-[22rem,1fr] gap-6 items-start">
      <div>
        <div className="text-lg font-semibold mb-2">Presets</div>
        <div className={`${TOK.card} p-3`}>
          <div className="space-y-2">
            {presets.map(p=>(
              <button key={p.id} onClick={()=>setSelectedId(p.id)}
                className={`w-full text-left px-3 py-2 rounded-md border ${selectedId===p.id?'bg-indigo-50 border-indigo-200':'bg-white border-stone-200 hover:bg-stone-50'}`}>
                <div className="text-sm font-medium">{p.name}</div>
                <div className="text-[11px] text-stone-500">{p.sizeIN.w}×{p.sizeIN.h} in — {p.colors||"4/4"}</div>
              </button>
            ))}
            <button className={`${TOK.btn} ${TOK.btnGhost} w-full`} onClick={addNew}>+ Add preset</button>
          </div>
        </div>
      </div>

      <div className={`${TOK.stack}`}>
        <div className={`${TOK.card} p-4 ${TOK.stack}`}>
          {!local ? (
            <div className="text-sm text-stone-600">Select a preset on the left.</div>
          ) : (
            <>
              {/* First line: Name only */}
              <div className="grid grid-cols-12 gap-2 md:gap-3">
                <div className="col-span-12">
                  <Field label="Name">
                    <Input value={local.name} onChange={(e)=>updateLocal("name", e.target.value)}/>
                  </Field>
                </div>
              </div>

              <Section title="Layout">
                <div className="grid grid-cols-1 md:grid-cols-[1fr,auto] md:gap-4 gap-2 items-start">
                  {/* Left controls */}
                  <div className={`${TOK.stack}`}>
                    {/* Paper - Sheet W - Sheet H */}
                    <div className="grid grid-cols-12 gap-2 md:gap-3 items-end">
                      <div className="col-span-12 md:col-span-6">
                        <Field label="Paper (default)">
                          <Select
                            value={local.defaultSubstrate}
                            onChange={(e)=>changePresetPaper(e.target.value)}
                          >
                            {loadInventory().map(s=><option key={s.sku} value={s.sku}>{s.name} ({s.sku})</option>)}
                          </Select>
                        </Field>
                      </div>
                      <div className="col-span-6 md:col-span-3">
                        <Field label="Sheet Width" hint="in">
                          <Input type="number" step="any" inputMode="decimal"
                                 value={local.sheetWIN} nudgeStep={0.125}
                                 onChange={(e)=>updateLocal("sheetWIN", Number(e.target.value)||0)} suffix="in"/>
                        </Field>
                      </div>
                      <div className="col-span-6 md:col-span-3">
                        <Field label="Sheet Height" hint="in">
                          <Input type="number" step="any" inputMode="decimal"
                                 value={local.sheetHIN} nudgeStep={0.125}
                                 onChange={(e)=>updateLocal("sheetHIN", Number(e.target.value)||0)} suffix="in"/>
                        </Field>
                      </div>
                    </div>

                    {/* Width - Height - Bleed - Gutter */}
                    <div className="grid grid-cols-12 gap-2 md:gap-3 items-end">
                      <div className="col-span-6 md:col-span-3">
                        <Field label="Width" hint="in">
                          <Input type="number" step="any" inputMode="decimal"
                                 value={local.sizeIN.w} nudgeStep={0.0625}
                                 onChange={(e)=>updateLocal("sizeIN", {...local.sizeIN, w:Number(e.target.value)||0})} suffix="in"/>
                        </Field>
                      </div>
                      <div className="col-span-6 md:col-span-3">
                        <Field label="Height" hint="in">
                          <Input type="number" step="any" inputMode="decimal"
                                 value={local.sizeIN.h} nudgeStep={0.0625}
                                 onChange={(e)=>updateLocal("sizeIN", {...local.sizeIN, h:Number(e.target.value)||0})} suffix="in"/>
                        </Field>
                      </div>
                      <div className="col-span-6 md:col-span-3">
                        <Field label="Bleed (preview)" hint="in">
                          <Input type="number" step="any" inputMode="decimal"
                                 value={previewBleed} nudgeStep={0.0625}
                                 onChange={(e)=>setPreviewBleed(Number(e.target.value)||0)} suffix="in"/>
                        </Field>
                      </div>
                      <div className="col-span-6 md:col-span-3">
                        <Field label="Gutter (preview)" hint="in">
                          <Input type="number" step="any" inputMode="decimal"
                                 value={previewGutter} nudgeStep={0.0625}
                                 onChange={(e)=>setPreviewGutter(Number(e.target.value)||0)} suffix="in"/>
                        </Field>
                      </div>
                    </div>

                    {/* Columns - Rows (preview only) */}
                    <div className="grid grid-cols-12 gap-2 md:gap-3 items-end">
                      <div className="col-span-6 md:col-span-3">
                        <Field label="Columns (Across)">
                          <Input type="number" inputMode="numeric" min={0}
                                 value={prevCols} nudgeStep={1}
                                 onChange={(e)=>setPrevCols(Math.max(0, Number(e.target.value)||0))}/>
                        </Field>
                      </div>
                      <div className="col-span-6 md:col-span-3">
                        <Field label="Rows (Around)">
                          <Input type="number" inputMode="numeric" min={0}
                                 value={prevRows} nudgeStep={1}
                                 onChange={(e)=>setPrevRows(Math.max(0, Number(e.target.value)||0))}/>
                        </Field>
                      </div>
                    </div>
                  </div>

                  {/* Right: diagram, no metrics */}
                  <div className="md:justify-self-end">
                    {previewLine && <LayoutDiagram line={previewLine} showMetrics={false} />}
                  </div>
                </div>
              </Section>

              <div className="mt-1 flex gap-2">
                <button className={`${TOK.btn} ${TOK.btnPri}`} onClick={save}>Save</button>
                <button className={`${TOK.btn} ${TOK.btnDanger}`} onClick={remove}>Delete</button>
              </div>
            </>
          )}
        </div>
      </div>
    </div>
  );
}

/* ---------------- Pricing Page ---------------- */
function PricingPage(){
  const { pricing, setPricing } = usePricing();
  const [local, setLocal] = useState(pricing);

  useEffect(()=>setLocal(pricing), [pricing]);

  // helpers
  const update = (path, value) => {
    setLocal(prev=>{
      const next = structuredClone(prev);
      const segs = path.split(".");
      let obj = next;
      for(let i=0;i<segs.length-1;i++){ obj = obj[segs[i]]; }
      obj[segs[segs.length-1]] = value;
      return next;
    });
  };
  const commit = () => { setPricing(local); };
  const resetDefaults = () => {
    const seed = { device: DEFAULT_DEVICE, clickRates: DEFAULT_CLICK_RATES, finishing: DEFAULT_FINISHING, global: DEFAULT_GLOBAL };
    setLocal(seed);
  };

  // finishing operations
  const addFinish = () => {
    const id = `F-${Math.random().toString(36).slice(2,6).toUpperCase()}`;
    update("finishing", [...local.finishing, { id, name:"New Step", setupMinutes:0, costPerUnit:0 }]);
  };
  const removeFinish = (id) => update("finishing", local.finishing.filter(f=>f.id!==id));

  return (
    <div className="mx-auto max-w-6xl md:pl-20 px-4 md:px-8 space-y-4">
      <div className="flex items-center justify-between">
        <div className="text-lg font-semibold">Pricing — Defaults</div>
        <div className="flex gap-2">
          <button className={`${TOK.btn} ${TOK.btnGhost}`} onClick={resetDefaults}>Reset to defaults</button>
          <button className={`${TOK.btn} ${TOK.btnPri}`} onClick={commit}>Save</button>
        </div>
      </div>

      {/* Device */}
      <div className={`${TOK.card} p-4 ${TOK.stack}`}>
        <div className={TOK.h2}>Device</div>
        <div className="grid grid-cols-12 gap-2 md:gap-3">
          <div className="col-span-6 md:col-span-3">
            <Field label="Setup time" hint="minutes">
              <Input type="number" step="1" inputMode="decimal"
                     value={local.device.setupMinutes} nudgeStep={1}
                     onChange={(e)=>update("device.setupMinutes", Math.max(0, Number(e.target.value)||0))} suffix="min"/>
            </Field>
          </div>
          <div className="col-span-6 md:col-span-3">
            <Field label="Run speed" hint="impressions/hour">
              <Input type="number" step="100" inputMode="decimal"
                     value={local.device.runSpeedIPH} nudgeStep={100}
                     onChange={(e)=>update("device.runSpeedIPH", Math.max(1, Number(e.target.value)||0))} suffix="iph"/>
            </Field>
          </div>
          <div className="col-span-6 md:col-span-3">
            <Field label="Overhead" hint="$ / hour">
              <Input type="number" step="0.01" inputMode="decimal"
                     value={local.device.overheadPerHour} nudgeStep={1}
                     onChange={(e)=>update("device.overheadPerHour", Math.max(0, Number(e.target.value)||0))} prefix="$"/>
            </Field>
          </div>
          <div className="col-span-6 md:col-span-3">
            <Field label="Default waste %" hint="percent">
              <Input type="number" step="0.1" inputMode="decimal"
                     value={Math.round((local.device.wastePctDefault||0)*100)} nudgeStep={1}
                     onChange={(e)=>update("device.wastePctDefault", Math.max(0, (Number(e.target.value)||0)/100))} suffix="%"/>
            </Field>
          </div>
        </div>
      </div>

      {/* Click costs (fixed, no breaks) */}
      <div className={`${TOK.card} p-4 ${TOK.stack}`}>
        <div className={TOK.h2}>Click Costs</div>
        <div className="grid grid-cols-12 gap-2 md:gap-3">
          <div className="col-span-6 md:col-span-3">
            <Field label="Color click" hint="$ / impression">
              <Input type="number" step="0.001" inputMode="decimal"
                     value={local.clickRates.color} nudgeStep={0.005}
                     onChange={(e)=>update("clickRates.color", Math.max(0, Number(e.target.value)||0))} prefix="$"/>
            </Field>
          </div>
          <div className="col-span-6 md:col-span-3">
            <Field label="B/W click" hint="$ / impression">
              <Input type="number" step="0.001" inputMode="decimal"
                     value={local.clickRates.bw} nudgeStep={0.005}
                     onChange={(e)=>update("clickRates.bw", Math.max(0, Number(e.target.value)||0))} prefix="$"/>
            </Field>
          </div>
        </div>
      </div>

      {/* Finishing */}
      <div className={`${TOK.card} p-4 ${TOK.stack}`}>
        <div className="flex items-center justify-between">
          <div className={TOK.h2}>Finishing Steps</div>
          <button className={`${TOK.btn} ${TOK.btnGhost}`} onClick={addFinish}>+ Add step</button>
        </div>
        <div className="border rounded-md overflow-hidden">
          <table className="min-w-full text-sm">
            <thead className="bg-stone-50">
              <tr>
                <th className="px-3 py-2 text-left">Name</th>
                <th className="px-3 py-2 text-left">Setup (min)</th>
                <th className="px-3 py-2 text-left">Cost / unit</th>
                <th className="px-3 py-2 text-right">Actions</th>
              </tr>
            </thead>
            <tbody>
              {local.finishing.map((f)=>(
                <tr key={f.id} className="border-t">
                  <td className="px-3 py-2">
                    <Input value={f.name} onChange={(e)=>{
                      const list=local.finishing.map(x=>x.id===f.id?{...x, name:e.target.value}:x);
                      update("finishing", list);
                    }}/>
                  </td>
                  <td className="px-3 py-2">
                    <Input type="number" step="1" inputMode="decimal"
                           value={f.setupMinutes} nudgeStep={1} onChange={(e)=>{
                      const list=local.finishing.map(x=>x.id===f.id?{...x, setupMinutes:Math.max(0, Number(e.target.value)||0)}:x);
                      update("finishing", list);
                    }}/>
                  </td>
                  <td className="px-3 py-2">
                    <Input type="number" step="0.001" inputMode="decimal"
                           value={f.costPerUnit} nudgeStep={0.005} onChange={(e)=>{
                      const list=local.finishing.map(x=>x.id===f.id?{...x, costPerUnit:Math.max(0, Number(e.target.value)||0)}:x);
                      update("finishing", list);
                    }} prefix="$"/>
                  </td>
                  <td className="px-3 py-2 text-right">
                    <button className={`${TOK.btn} ${TOK.btnDanger}`} onClick={()=>removeFinish(f.id)}>Delete</button>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </div>

      {/* Global defaults */}
      <div className={`${TOK.card} p-4 ${TOK.stack}`}>
        <div className={TOK.h2}>Global Defaults</div>
        <div className="grid grid-cols-12 gap-2 md:gap-3">
          <div className="col-span-6 md:col-span-3">
            <Field label="Default Margin %" hint="used when preset doesn’t set one">
              <Input type="number" step="0.1" inputMode="decimal"
                     value={Math.round((local.global.defaultMarginPct||0)*100)} nudgeStep={1}
                     onChange={(e)=>update("global.defaultMarginPct", Math.max(0, (Number(e.target.value)||0)/100))} suffix="%"/>
            </Field>
          </div>
        </div>
      </div>
    </div>
  );
}

/* ---------------- Quotes: list page ---------------- */
function QuotesPage(){
  const [quotes, setQuotes] = useState(()=>loadQuotes().sort((a,b)=> (b.createdAt||"").localeCompare(a.createdAt||"")));
  useEffect(()=>{ saveQuotes(quotes); },[quotes]);

  return (
    <div className="mx-auto max-w-6xl md:pl-20 px-4 md:px-8 space-y-3">
      <div className="flex items-center justify-between">
        <div className="text-lg font-semibold">Quotes</div>
      </div>

      <div className={`${TOK.card} p-0 overflow-hidden`}>
        <table className="min-w-full text-sm">
          <thead className="bg-stone-50">
            <tr>
              <th className="px-3 py-2 text-left">Created</th>
              <th className="px-3 py-2 text-left">Customer</th>
              <th className="px-3 py-2 text-left">Title</th>
              <th className="px-3 py-2 text-right">Total</th>
              <th className="px-3 py-2 text-left">Status</th>
              <th className="px-3 py-2 text-right">Actions</th>
            </tr>
          </thead>
          <tbody>
            {quotes.map(q=>(
              <tr key={q.id} className="border-t">
                <td className="px-3 py-2">{q.createdAt ? new Date(q.createdAt).toLocaleString() : "—"}</td>
                <td className="px-3 py-2">{q.customer||"—"}</td>
                <td className="px-3 py-2">{q.title||"—"}</td>
                <td className="px-3 py-2 text-right">{money(q.total||0)}</td>
                <td className="px-3 py-2">{q.status||"Draft"}</td>
                <td className="px-3 py-2 text-right">
                  <button className={`${TOK.btn} ${TOK.btnGhost}`} onClick={()=>{ location.hash = `/quote/${q.id}`; }}>View</button>
                </td>
              </tr>
            ))}
            {quotes.length===0 && (
              <tr><td className="px-3 py-6 text-center text-stone-500" colSpan={6}>No quotes yet. Create one from the Job page.</td></tr>
            )}
          </tbody>
        </table>
      </div>
    </div>
  );
}

/* ---------------- Quote preview (print-friendly) ---------------- */
function QuotePreview({ quoteId }){
  const [quotes, setQuotes] = useState(()=>loadQuotes());
  const q = quotes.find(x=>x.id===quoteId);
  const { pricing } = usePricing();

  useEffect(()=>{ saveQuotes(quotes); },[quotes]);

  if(!q){
    return (
      <div className="mx-auto max-w-4xl md:pl-20 px-4 md:px-8">
        <div className="text-lg font-semibold">Quote Not Found</div>
        <div className={`${TOK.card} p-4 mt-2`}>
          This quote may have been deleted. <button className={`${TOK.btn} ${TOK.btnGhost} ml-2`} onClick={()=>location.hash='/quotes'}>Back to Quotes</button>
        </div>
      </div>
    );
  }

  const mark = (patch) => {
    setQuotes(prev=>{
      const idx = prev.findIndex(x=>x.id===q.id);
      if(idx<0) return prev;
      const next = [...prev];
      next[idx] = { ...next[idx], ...patch };
      return next;
    });
  };

  const accept = () => {
    const name = prompt("Enter name of person accepting (optional):") || "";
    mark({ status: "Accepted", acceptedAt: new Date().toISOString(), acceptedBy: name });
  };
  const decline = () => mark({ status: "Declined" });
  const markSent = () => mark({ status: "Sent", createdAt: q.createdAt || new Date().toISOString() });
  const markViewed = () => mark({ status: "Viewed" });

  const subtotal = q.lines?.reduce((s,l)=> s + (l.calc?.sell||0), 0) || 0;
  const total = subtotal * (1 + (Number(q.taxPct)||0)/100);

  return (
    <div className="mx-auto max-w-5xl md:pl-20 px-4 md:px-8 space-y-3">
      <div className="flex items-center justify-between print:hidden">
        <div className="text-lg font-semibold">Quote Preview</div>
        <div className="flex gap-2">
          <button className={`${TOK.btn} ${TOK.btnGhost}`} onClick={()=>location.hash='/job'}>Back to Job</button>
          <button className={`${TOK.btn} ${TOK.btnGhost}`} onClick={()=>location.hash='/quotes'}>All Quotes</button>
          <button className={`${TOK.btn} ${TOK.btnPri}`} onClick={()=>window.print()}>Print / PDF</button>
        </div>
      </div>

      <div className={`${TOK.card} p-6`}>
        {/* Header */}
        <div className="flex items-start justify-between">
          <div>
            <div className="text-2xl font-semibold">Estimate</div>
            <div className="text-sm text-stone-500">#{q.id.slice(0,8)}</div>
            <div className="mt-2 text-sm"><span className="text-stone-500">Date:</span> {q.createdAt ? new Date(q.createdAt).toLocaleDateString() : new Date().toLocaleDateString()}</div>
            <div className="text-sm"><span className="text-stone-500">Status:</span> <span className="font-medium">{q.status||"Draft"}</span></div>
            {q.status==="Accepted" && (
              <div className="text-sm text-emerald-700">
                Accepted {q.acceptedAt ? new Date(q.acceptedAt).toLocaleString() : ""} {q.acceptedBy ? `by ${q.acceptedBy}` : ""}
              </div>
            )}
          </div>
          <div className="text-right">
            <div className="font-semibold">{q.customer||"Customer"}</div>
            <div className="text-sm text-stone-500">{q.title||"Untitled Quote"}</div>
          </div>
        </div>

        {/* Lines */}
        <div className="mt-4 border rounded-md overflow-hidden">
          <table className="min-w-full text-sm">
            <thead className="bg-stone-50">
              <tr>
                <th className="px-3 py-2 text-left">Line</th>
                <th className="px-3 py-2 text-right">Qty</th>
                <th className="px-3 py-2 text-right">Unit</th>
                <th className="px-3 py-2 text-right">Total</th>
              </tr>
            </thead>
            <tbody>
              {(q.lines||[]).map((l, i)=>{
                const unit = (l.calc?.sell||0) / (l.qty||1);
                return (
                  <tr key={l.id} className="border-t">
                    <td className="px-3 py-2">
                      <div className="font-medium">{l.name||`Line ${i+1}`}</div>
                      <div className="text-[11px] text-stone-500">
                        {l.sizeIN?.w}×{l.sizeIN?.h} in • {l.colors||"4/4"} • {l.qty} pcs • {l.substrateSku}
                      </div>
                    </td>
                    <td className="px-3 py-2 text-right">{l.qty}</td>
                    <td className="px-3 py-2 text-right">{money(unit)}</td>
                    <td className="px-3 py-2 text-right">{money(l.calc?.sell||0)}</td>
                  </tr>
                );
              })}
            </tbody>
          </table>
        </div>

        {/* Totals */}
        <div className="mt-3 grid grid-cols-1 md:grid-cols-2 gap-4 items-start">
          <div className="text-sm text-stone-600">
            <div className="font-medium text-stone-800 mb-1">Notes / Terms</div>
            <ul className="list-disc ml-5 space-y-1">
              <li>Pricing valid for 15 days.</li>
              <li>Sales tax applied where applicable.</li>
              <li>Production schedule starts upon approval &amp; payment.</li>
            </ul>
          </div>
          <div className="ml-auto w-full md:w-80">
            <div className="border rounded-md p-3 space-y-1 text-sm">
              <div className="flex justify-between"><span>Subtotal</span><span className="font-semibold">{money(subtotal)}</span></div>
              <div className="flex justify-between"><span>Tax ({q.taxPct||0}%)</span><span className="font-semibold">{money(subtotal*(Number(q.taxPct||0)/100))}</span></div>
              <div className="border-t pt-2 flex justify-between text-base font-semibold"><span>Total</span><span>{money(total)}</span></div>
            </div>
          </div>
        </div>

        {/* Actions */}
        <div className="mt-4 flex flex-wrap gap-2 print:hidden">
          <button className={`${TOK.btn} ${TOK.btnGhost}`} onClick={markSent}>Mark Sent</button>
          <button className={`${TOK.btn} ${TOK.btnGhost}`} onClick={markViewed}>Mark Viewed</button>
          <button className={`${TOK.btn} ${TOK.btnPri}`} onClick={accept}>Accept</button>
          <button className={`${TOK.btn} ${TOK.btnDanger}`} onClick={decline}>Decline</button>
        </div>
      </div>
    </div>
  );
}

/* ---------------- App ---------------- */
export default function App(){
  const [route, goto] = useHashRoute();
  const [presets, setPresets] = useState(()=>loadPresetsLS());
  const [pricing, setPricingState] = useState(()=>loadPricing());

  useEffect(()=>{ savePresetsLS(presets); }, [presets]);
  const setPricing = (p)=>{ setPricingState(p); savePricing(p); };

  const ctxValue = useMemo(()=>({ pricing, setPricing }), [pricing]);

  const isQuoteRoute = route.startsWith("/quote/");
  const quoteId = isQuoteRoute ? route.split("/")[2] : null;

  return (
    <PricingCtx.Provider value={ctxValue}>
      <div className="min-h-screen bg-stone-100 text-stone-900">
        <Sidebar route={route} goto={goto}/>
        <header className={TOK.header}>
          <div className="flex items-center gap-3 md:pl-20">
            <div className="h-8 w-8 rounded-md bg-indigo-600"></div>
            <div className="font-semibold">Estimator — Prototype</div>
            <div className="text-xs text-stone-500">v0.12.0</div>
          </div>
          <TopTabs route={route} goto={goto}/>
        </header>

        <main className="pb-6">
          {route==="/job" && <JobPage presets={presets}/>}
          {route==="/customer" && <CustomerPage/>}
          {route==="/presets" && <PresetsPage presets={presets} setPresets={setPresets}/>}
          {route==="/pricing" && <PricingPage/>}
          {route==="/quotes" && <QuotesPage/>}
          {isQuoteRoute && <QuotePreview quoteId={quoteId}/>}
          {route==="/inventory" && <InventoryPage/>}
        </main>
      </div>
    </PricingCtx.Provider>
  );
}
