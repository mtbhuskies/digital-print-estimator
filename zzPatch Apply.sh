git checkout -b chore/fix-compile-911
git apply -p0 /dev/stdin <<'PATCH'
*** Begin Patch
*** Update File: src/App.jsx
@@
-import React, { useMemo, useState, useEffect, useRef } from "react";
+import React, { useMemo, useState, useEffect, useRef } from "react";
 
 /* ---------------- UI tokens ---------------- */
 const TOK = {
   card: "bg-white rounded-[var(--radius)] shadow-sm border border-stone-200",
   header: "px-6 py-4 border-b bg-white flex items-center justify-between sticky top-0 z-30",
@@
   subTitle: "text-[11px] text-stone-500"
 };
 
 /* tiny helpers for keyboard nudges (F14) */
 const nudger = (e, step, toNumber=(v)=>Number(v)||0) => {
   if (e.key !== "ArrowUp" && e.key !== "ArrowDown") return;
   e.preventDefault();
   const cur = toNumber(e.currentTarget.value);
   e.currentTarget.value = (cur + (e.key==="ArrowUp"? +step : -step)).toString();
   e.currentTarget.dispatchEvent(new Event("input", { bubbles: true }));
 };
 
@@
   return [path, (p)=>{ location.hash = p; }];
 }
 
 /* ---------------- Costing / constants ---------------- */
 const DEVICE = { setupMinutes: 6, runSpeedIPH: 2400, overheadPerHour: 28.0,
   clickTiers: [{ breakQty: 0, costPerClick: 0.07 }, { breakQty: 1000, costPerClick: 0.055 }, { breakQty: 5000, costPerClick: 0.045 }] };
 
 // costing fallback (only if inventory doesn’t have the chosen stock)
 const SUBSTRATES = [
   { sku: "SMOOTH-120C", name: "Smooth White 120# Cover", size: { wMM: 330, hMM: 482 }, costPerPack: 145.0, unitsPerPack: 200, wasteFixedSheets: 10, wastePct: 0.025, costPerSheet: 145.0 / 200 },
   { sku: "TEXT-100",   name: "Text 100#",               size: { wMM: 330, hMM: 482 }, costPerPack: 82.0,  unitsPerPack: 500, wasteFixedSheets: 8,  wastePct: 0.02,  costPerSheet: 82.0  / 500 },
 ];
 
 const FINISHING = [
   { id: "TRIM",  name: "Trim to size", setupMinutes: 2, costPerUnit: 0.01 },
   { id: "SCORE", name: "Score/Fold",  setupMinutes: 4, costPerUnit: 0.03 },
 ];
 
 const DEFAULT_PRESETS = [
   // Added sheetW/ sheetH to support Presets page preview; defaults to 13x19
   { id: "BUS-CARD", name: "Business Cards", sizeIN: { w: 3.5, h: 2.0 }, sheetWIN: 13, sheetHIN: 19,
     sides: 2, defaultSubstrate: "SMOOTH-120C", defaultFinishing: ["TRIM"],
     qtyBreaks: [50, 100, 250, 500, 1000, 2500], defaultMarginPct: 0.55 },
   { id: "POSTCARD", name: "Postcards", sizeIN: { w: 6.0, h: 4.0 }, sheetWIN: 13, sheetHIN: 19,
     sides: 2, defaultSubstrate: "SMOOTH-120C", defaultFinishing: ["TRIM"],
     qtyBreaks: [50, 100, 250, 500, 1000], defaultMarginPct: 0.50 },
   { id: "FLYER",    name: "Flyers", sizeIN: { w: 8.5, h: 11.0 }, sheetWIN: 13, sheetHIN: 19,
     sides: 2, defaultSubstrate: "TEXT-100", defaultFinishing: [],
     qtyBreaks: [50, 100, 250, 500, 1000], defaultMarginPct: 0.48 },
 ];
 
 /* ---------------- Utils ---------------- */
 const roundToInc = (v, inc = 0.05) => Math.round(v / inc) * inc;
 const clamp = (n, min, max) => Math.max(min, Math.min(max, n));
 const money = (n) => n.toLocaleString(undefined, { style: "currency", currency: "USD" });
 const IN_TO_MM = 25.4;
 const inToMM = (inches) => inches * IN_TO_MM;
 const mmToIn = (mm) => mm / IN_TO_MM;
 
 /* ---------------- Inventory storage ---------------- */
 const loadInventory = () => { try { return JSON.parse(localStorage.getItem("inventory")||"null")||[]; } catch { return []; } };
 const saveInventory = (arr) => localStorage.setItem("inventory", JSON.stringify(arr));
 
 /* ---------------- Presets storage ---------------- */
 const PRESETS_KEY = "presets_v1";
 function loadPresetsLS(){
   try {
     const v = JSON.parse(localStorage.getItem(PRESETS_KEY)||"null");
     if (Array.isArray(v) && v.length) return v;
   } catch {}
   // seed defaults on first load
   localStorage.setItem(PRESETS_KEY, JSON.stringify(DEFAULT_PRESETS));
   return DEFAULT_PRESETS;
 }
 function savePresetsLS(p){ localStorage.setItem(PRESETS_KEY, JSON.stringify(p)); }
 
 /* ---------------- Helpers ---------------- */
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
   // Prefer user override; else inventory size; else fallback
   const invList = loadInventory();
   const inv = invList.find(x=>x.sku===line.substrateSku);
   const invSz = inv ? parseSizeInches(inv.size) : null;
   const fallback = findSubstrateFallback(line.substrateSku).size;
 
   const hasOverride = (line.sheetWOverrideIN||0) > 0 && (line.sheetHOverrideIN||0) > 0;
   if(hasOverride) return { wMM: inToMM(line.sheetWOverrideIN), hMM: inToMM(line.sheetHOverrideIN) };
   if(invSz) return { wMM: inToMM(invSz.w), hMM: inToMM(invSz.h) };
   return fallback;
 }
 const clicksCostForQty = (qty) =>
   DEVICE.clickTiers.reduce((acc, t) => (qty >= t.breakQty ? t.costPerClick : acc), DEVICE.clickTiers[0].costPerClick);
 
 const fitUpOnSheet = (itemMM, sheetMM) => {
   const up1 = Math.floor(sheetMM.wMM / itemMM.wMM) * Math.floor(sheetMM.hMM / itemMM.hMM);
   const up2 = Math.floor(sheetMM.wMM / itemMM.hMM) * Math.floor(sheetMM.hMM / itemMM.wMM);
   return Math.max(1, Math.max(up1, up2));
 };
 
 function computeLineCosts(line) {
   const substrate = findSubstrateFallback(line.substrateSku);
   const sizeMM = { wMM: inToMM(line.sizeIN.w), hMM: inToMM(line.sizeIN.h) };
   const sheetMM = effectiveSheetSizeMM(line);
   const up = fitUpOnSheet(sizeMM, sheetMM);
   const wasteUnits = Math.ceil(line.qty * 0.02);
   const effectiveQty = line.qty + wasteUnits;
   const sheets = Math.ceil(effectiveQty / up);
   const clicks = sheets * line.sides;
   const clickRate = clicksCostForQty(clicks);
   const setupCost = (DEVICE.setupMinutes / 60) * DEVICE.overheadPerHour;
   const runMinutes = (clicks / DEVICE.runSpeedIPH) * 60;
   const overheadCost = (runMinutes / 60) * DEVICE.overheadPerHour;
   const clicksCost = clicks * clickRate;
   const substrateCost = sheets * substrate.costPerSheet;
   const finishingCost = (line.finishingStepIds||[]).reduce((sum, id) => {
     const step = FINISHING.find((f) => f.id === id);
     if (!step) return sum;
     return sum + (step.setupMinutes / 60) * DEVICE.overheadPerHour + step.costPerUnit * line.qty;
   }, 0);
   const baseCost = setupCost + overheadCost + clicksCost + substrateCost + finishingCost;
   const sell = roundToInc(baseCost * (1 + clamp(line.marginPct || 0.5, 0, 2)));
   return { up, sheets, clicks, clickRate, setupCost, overheadCost, clicksCost, substrateCost, finishingCost, baseCost, sell };
 }
 
 function computeLayout({ sheetW, sheetH, pieceWmm, pieceHmm, bleedMM, gutterMM, allowRotate=true }){
   const effW = pieceWmm + 2*bleedMM;
   const effH = pieceHmm + 2*bleedMM;
   const grid=(w,h)=>{
     const cols=Math.max(0,Math.floor((sheetW+gutterMM)/(w+gutterMM)));
     const rows=Math.max(0,Math.floor((sheetH+gutterMM)/(h+gutterMM)));
     const ups=cols*rows;
     const usedW=cols*w+Math.max(0,cols-1)*gutterMM;
     const usedH=rows*h+Math.max(0,rows-1)*gutterMM;
     const offX=Math.max(0,(sheetW-usedW)/2), offY=Math.max(0,(sheetH-usedH)/2);
     return {cols,rows,ups,w,h,offX,offY};
   };
   const A=grid(effW,effH), B=allowRotate?grid(effH,effW):{ups:-1};
   const best=A.ups>=B.ups?{...A,rot:0}:{...B,rot:90};
   const cells=[];
   for(let r=0;r<best.rows;r++){
     for(let c=0;c<best.cols;c++){
       const x=best.offX+c*(best.w+gutterMM);
       const y=best.offY+r*(best.h+gutterMM);
       cells.push({x,y,w:best.w,h:best.h});
     }
   }
   return {...best,cells};
 }
 
 function useContainerWidth(){
   const ref = useRef(null);
   const [w,setW]=useState(0);
   useEffect(()=>{
     if(!ref.current) return;
     const ro=new ResizeObserver(entries=>{
       for(const e of entries){ setW(Math.floor(e.contentRect.width)); }
     });
     ro.observe(ref.current);
     return ()=>ro.disconnect();
   },[]);
   return [ref,w];
 }
 
 /* ---------------- Diagram ---------------- */
 function LayoutDiagram({ line, showMetrics = true, compact = false }){
   const [wrapRef, wrapW]=useContainerWidth();
   
   const sheet = effectiveSheetSizeMM(line);
   const sheetW = sheet.wMM, sheetH = sheet.hMM;
   const pieceWmm = inToMM(line.sizeIN.w);
   const pieceHmm = inToMM(line.sizeIN.h);
   const bleedMM = inToMM(line.bleedIN||0);
   const gutterMM = inToMM(line.gutterIN||0);
   const layout = React.useMemo(()=>computeLayout({
     sheetW, sheetH, pieceWmm, pieceHmm, bleedMM, gutterMM, allowRotate: line.allowRotate!==false
   }), [sheetW,sheetH,pieceWmm,pieceHmm,bleedMM,gutterMM,line.allowRotate]);
   
   // Sizing:
   const PAD = 8;
   const maxH = 240;
   const maxW = Math.max(160, wrapW||240);
   
   // scale for Job (fit to container) or Presets (tight to content)
   const scale = compact
   ? (maxH - PAD*2) / sheetH
   : Math.min((maxW - PAD*2) / sheetW, (maxH - PAD*2) / sheetH);
   
   const toPx = (mm) => mm * scale;
   const svgW = compact ? (toPx(sheetW) + PAD*2) : maxW;  // compact: intrinsic width; job: fill column
   
   // Derived quick metrics (kept for Job when showMetrics===true)
   const sheets = Math.ceil((line.qty + Math.ceil(line.qty*0.02)) / Math.max(1, layout.ups));
   const clicks  = sheets * (line.sides||1);
   const clickRate = clicksCostForQty(clicks);
   const sheetArea = sheetW * sheetH;
   const usedArea  = (layout.cols||0) * (layout.rows||0) * (pieceWmm + 2*bleedMM) * (pieceHmm + 2*bleedMM)
                     + Math.max(0,(layout.cols-1)) * gutterMM * (layout.rows*(pieceHmm+2*bleedMM))
                     + Math.max(0,(layout.rows-1)) * gutterMM * (layout.cols*(pieceWmm+2*bleedMM));
   const wastePct  = sheetArea>0 ? Math.max(0, 1 - (usedArea / sheetArea)) * 100 : 0;
 
   
   return (
     <div ref={wrapRef} className={`mt-1 ${compact ? "w-fit" : ""}`}>
       <div className="text-[12px] font-semibold text-stone-700">Layout Diagram</div>
       <div className={`mt-2 ${compact ? "p-1" : "p-2"} bg-stone-50 border border-stone-200 rounded-lg`}>
         <svg style={{ width: svgW, height: maxH }} viewBox={`0 0 ${svgW} ${maxH}`} preserveAspectRatio="xMidYMid meet">
           {/* Sheet */}
           <rect x={PAD} y={PAD} width={toPx(sheetW)} height={toPx(sheetH)} fill="#fff" stroke="#475569" strokeWidth="1"/>
           {/* Gutter guides (B5) */}
           {Array.from({length: Math.max(0,(layout.cols||0)-1)}).map((_,i)=>(
             <line key={`gv${i}`} x1={PAD+toPx(layout.offX+(i+1)*(layout.w+gutterMM)-gutterMM/2)}
                   y1={PAD} x2={PAD+toPx(layout.offX+(i+1)*(layout.w+gutterMM)-gutterMM/2)} y2={PAD+toPx(sheetH)}
                   stroke="#94a3b8" strokeDasharray="3 3" />
           ))}
           {Array.from({length: Math.max(0,(layout.rows||0)-1)}).map((_,i)=>(
             <line key={`gh${i}`} y1={PAD+toPx(layout.offY+(i+1)*(layout.h+gutterMM)-gutterMM/2)}
                   x1={PAD} y2={PAD+toPx(layout.offY+(i+1)*(layout.h+gutterMM)-gutterMM/2)} x2={PAD+toPx(sheetW)}
                   stroke="#94a3b8" strokeDasharray="3 3" />
           ))}
           {/* Cells with bleed shading */}
           {layout.cells.map((cell,i)=>(
             <g key={i} transform={`translate(${PAD+toPx(cell.x)},${PAD+toPx(cell.y)})`}>
               <rect width={toPx(cell.w)} height={toPx(cell.h)} rx="4" ry="4" fill="#c7d2fe" stroke="#4338ca"/>
               {/* bleed shading */}
               <rect x="0" y="0" width={toPx(cell.w)} height={toPx(bleedMM)} fill="#e2e8f0" />
               <rect x="0" y={toPx(cell.h-bleedMM)} width={toPx(cell.w)} height={toPx(bleedMM)} fill="#e2e8f0" />
               <rect x="0" y="0" width={toPx(bleedMM)} height={toPx(cell.h)} fill="#e2e8f0" />
               <rect x={toPx(cell.w-bleedMM)} y="0" width={toPx(bleedMM)} height={toPx(cell.h)} fill="#e2e8f0" />
               {/* trimmed piece outline */}
               <rect x={toPx(bleedMM)} y={toPx(bleedMM)} width={toPx(cell.w-2*bleedMM)} height={toPx(cell.h-2*bleedMM)} fill="#fff" stroke="#1f2937" strokeDasharray="4 3"/>
             </g>
           ))}
           {/* Labels (B6) */}
           <text x={PAD+6} y={PAD+14} fontSize="11" fill="#334155">Sheet: {mmToIn(sheetW).toFixed(2)}×{mmToIn(sheetH).toFixed(2)} in</text>
           <text x={PAD+6} y={PAD+28} fontSize="11" fill="#334155">Piece: {line.sizeIN.w}×{line.sizeIN.h} in + {line.bleedIN||0}" bleed</text>
         </svg>
       </div>
 
       {showMetrics && (
         <div className="mt-2 grid grid-cols-2 gap-2 text-[11px]">
           <div className="border rounded-md px-2 py-1 bg-white flex justify-between"><span>Ups</span><span className="font-semibold">{layout.ups}</span></div>
           <div className="border rounded-md px-2 py-1 bg-white flex justify-between"><span>Sheets</span><span className="font-semibold">{sheets}</span></div>
           <div className="border rounded-md px-2 py-1 bg-white flex justify-between"><span>Clicks</span><span className="font-semibold">{clicks}</span></div>
           <div className="border rounded-md px-2 py-1 bg-white flex justify-between"><span>Click rate</span><span className="font-semibold">${clickRate.toFixed(3)}</span></div>
           <div className="border rounded-md px-2 py-1 bg-white flex justify-between"><span>Waste</span><span className="font-semibold">{wastePct.toFixed(1)}%</span></div>
         </div>
       )}
 
       {line._onChangeRotate && (
         <div className="mt-2">
           <label className="inline-flex items-center gap-2 text-xs">
             <input type="checkbox" className="accent-indigo-600"
               checked={line.allowRotate!==false}
               onChange={(e)=>line._onChangeRotate?.(e.target.checked)}/>
             Allow rotate
           </label>
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
 function Input({ value, onChange, type="text", placeholder, prefix, suffix, inputMode, ...rest }){
   const base = "h-field w-full pad-v rounded-md border text-sm px-3 transition outline-none";
   const state = "border-stone-300 focus:ring-2 focus:ring-indigo-300 focus:border-indigo-500";
   return (
     <div className="relative">
       {prefix && <div className="absolute left-3 top-1/2 -translate-y-1/2 text-[12px] text-stone-500">{prefix}</div>}
       <input className={`${base} ${state} ${prefix?'pl-7':'pl-3'} ${suffix?'pr-9':'pr-3'}`} value={value} onChange={onChange} type={type} placeholder={placeholder} inputMode={inputMode} {...rest} />
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
 
 /* ---------------- Sidebar ---------------- */
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
       {item("/inventory","Inventory")}
     </div>
   );
 }
 
 /* ---------------- Job / Line Item ---------------- */
 function LineCard({ line, onChange, onDuplicate, onDelete, presets, inventory }){
   const costs=useMemo(()=>computeLineCosts(line),[line]);
   const qtys=(presets.find(p=>p.id===line.presetId)?.qtyBreaks)||[50,100,250,500,1000,2500];
 
   /* C9 focus name after duplicate; F13 predicates */
   const nameRef = useRef(null);
   useEffect(()=>{ if(line.focusName && nameRef.current){ nameRef.current.focus(); nameRef.current.select(); onChange({...line, focusName:false}); } },[line.focusName]);
   const invalidQty = !Number.isFinite(line.qty) || line.qty<=0;
   const invalidSize = !line.sizeIN?.w || !line.sizeIN?.h || line.sizeIN.w<=0 || line.sizeIN.h<=0;
   const priceDisabled = invalidQty || invalidSize;
 
   function applyPreset(id){
     const p=presets.find(x=>x.id===id); if(!p) return;
     // Prefill sheet W/H from inventory if sku exists; else fallback to static
     const inv=inventory.find(s=>s.sku=== (p.defaultSubstrate||line.substrateSku));
     const invSz=inv?parseSizeInches(inv.size):null;
     const fb = findSubstrateFallback(p.defaultSubstrate||line.substrateSku).size;
     onChange({...line,
       presetId:id,
       name: line.name || p.name,
       sizeIN:{...p.sizeIN},
       sides:p.sides||line.sides,
       substrateSku:p.defaultSubstrate||line.substrateSku,
       sheetWOverrideIN: invSz?invSz.w:(p.sheetWIN||mmToIn(fb.wMM)),
       sheetHOverrideIN: invSz?invSz.h:(p.sheetHIN||mmToIn(fb.hMM)),
       marginPct:p.defaultMarginPct??line.marginPct,
       finishingStepIds:[...(p.defaultFinishing||[])] });
   }
 
   function changePaper(sku){
     const inv=inventory.find(s=>s.sku===sku);
     const invSz=inv?parseSizeInches(inv.size):null;
     const fb=findSubstrateFallback(sku).size;
     onChange({...line,
       substrateSku: sku,
       sheetWOverrideIN: invSz?invSz.w:mmToIn(fb.wMM),
       sheetHOverrideIN: invSz?invSz.h:mmToIn(fb.hMM),
     });
   }
 
   const invPaper = inventory.find(s=>s.sku===line.substrateSku);
   const parsedInvSz = invPaper?parseSizeInches(invPaper.size):null;
   const effSheetWIn = line.sheetWOverrideIN || (parsedInvSz?parsedInvSz.w:mmToIn(findSubstrateFallback(line.substrateSku).size.wMM));
   const effSheetHIn = line.sheetHOverrideIN || (parsedInvSz?parsedInvSz.h:mmToIn(findSubstrateFallback(line.substrateSku).size.hMM));
 
   return (
     <div className={`${TOK.card} p-4 space-y-3`}>
       <Section title="Line item">
         <div className="grid grid-cols-12 md:gap-3 gap-2 items-end">
           <div className="col-span-12 md:col-span-7">
             <Field label="Name">
               {/* C9: native input for focus/select */}
               <input ref={nameRef} className="h-field w-full pad-v rounded-md border text-sm px-3 transition outline-none border-stone-300 focus:ring-2 focus:ring-indigo-300 focus:border-indigo-500"
                      value={line.name||""}
                      onChange={(e)=>onChange({...line, name:e.target.value})}
                      placeholder="e.g., Business Cards for Spring Promo"/>
             </Field>
           </div>
           <div className="col-span-6 md:col-span-2">
             <Field label="Qty">
               <Input inputMode="numeric" value={line.qty}
                      onKeyDown={(e)=>nudger(e,25,(v)=>Number(v)||0)}
                      onChange={(e)=>onChange({...line, qty: Number(e.target.value)||0})}/>
               {invalidQty && <div className="mt-1 text-[11px] text-rose-600">Enter a quantity &gt; 0</div>}
             </Field>
           </div>
           <div className="col-span-6 md:col-span-3 flex md:hidden justify-end gap-2">
             <button className={`${TOK.btn} ${TOK.btnSec}`} onClick={onDuplicate}>Duplicate</button>
             <button className={`${TOK.btn} ${TOK.btnDanger}`} onClick={onDelete}>Delete</button>
           </div>
         </div>
       </Section>
 
       <Section title="Layout">
         {/* 4/5 controls (left) — 1/5 diagram (right) */}
         <div className="grid grid-cols-1 md:grid-cols-5 md:gap-4 gap-2">
           {/* Left controls (3/5) */}
           <div className="md:col-span-3 space-y-3">
             {/* Preset row */}
             <div className="grid grid-cols-12 gap-2 md:gap-3 items-end">
               <div className="col-span-12 lg:col-span-6">
                 <Field label="Preset">
                   <input list={`preset-list-${line.id}`} className="h-field w-full rounded-md border text-sm px-3 border-stone-300 focus:ring-2 focus:ring-indigo-300 focus:border-indigo-500"
                          placeholder="Type to search presets"
                          defaultValue={presets.find(p=>p.id===line.presetId)?.name||""}
                          onChange={(e)=>{
                            const byName = presets.find(p=>p.name.toLowerCase()===e.target.value.toLowerCase());
                            if(byName) applyPreset(byName.id);
                          }}/>
                   <datalist id={`preset-list-${line.id}`}>
                     <option value="Custom"></option>
                     {presets.map(p=><option key={p.id} value={p.name}></option>)}
                   </datalist>
                 </Field>
               </div>
               <div className="col-span-6 lg:col-span-3">
                 <Field label="Sides"><Input inputMode="numeric" value={line.sides||2} onChange={(e)=>onChange({...line, sides: Number(e.target.value)||1})}/></Field>
               </div>
               <div className="col-span-6 lg:col-span-3"></div>
             </div>
 
             {/* Paper from Inventory + Sheet override prefilled */}
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
                   <Input value={Number((effSheetWIn||0).toFixed(3))}
                          disabled={!!line.sheetLocked}
                          onChange={(e)=>onChange({...line, sheetWOverrideIN: Number(e.target.value)||0})}
                          onKeyDown={(e)=>nudger(e,0.125,(v)=>Number(v)||0)}
                          suffix="in" inputMode="decimal"/>
                 </Field>
               </div>
               <div className="col-span-6 md:col-span-3">
                 <Field label="Sheet Height" hint="in">
                   <Input value={Number((effSheetHIn||0).toFixed(3))}
                          disabled={!!line.sheetLocked}
                          onChange={(e)=>onChange({...line, sheetHOverrideIN: Number(e.target.value)||0})}
                          onKeyDown={(e)=>nudger(e,0.125,(v)=>Number(v)||0)}
                          suffix="in" inputMode="decimal"/>
                 </Field>
               </div>
               <div className="col-span-12">
                 <button type="button" className={`${TOK.btn} ${TOK.btnGhost} !h-7 !px-2`}
                         title={line.sheetLocked?"Sizes locked to inventory. Click to unlock for manual override.":"Manual override active. Click to relock to inventory size."}
                         onClick={()=>{
                           if(line.sheetLocked){
                             onChange({...line, sheetLocked:false});
                           }else{
                             const invPaper = inventory.find(s=>s.sku===line.substrateSku);
                             const invSz = invPaper ? parseSizeInches(invPaper.size) : null;
                             const fb = findSubstrateFallback(line.substrateSku).size;
                             onChange({...line, sheetLocked:true,
                               sheetWOverrideIN: invSz?invSz.w:mmToIn(fb.wMM),
                               sheetHOverrideIN: invSz?invSz.h:mmToIn(fb.hMM)
                             });
                           }
                         }}>
                   {line.sheetLocked ? "🔒 Locked to inventory size" : "🔓 Manual override (sheet size)"}
                 </button>
               </div>
             </div>
 
             {/* Size + Bleed/Gutter */}
             <div className="grid grid-cols-12 gap-2 md:gap-3 items-end">
               <div className="col-span-6 md:col-span-3">
                 <Field label="Width" hint="in">
                   <Input value={line.sizeIN.w}
                          onChange={(e)=>onChange({...line, sizeIN:{...line.sizeIN, w:Number(e.target.value)||0}})}
                          suffix="in" inputMode="decimal"
                          onKeyDown={(e)=>nudger(e,0.0625,(v)=>Number(v)||0)}
                          />
                 </Field>
               </div>
               <div className="col-span-6 md:col-span-3">
                 <Field label="Height" hint="in">
                   <Input value={line.sizeIN.h}
                          onChange={(e)=>onChange({...line, sizeIN:{...line.sizeIN, h:Number(e.target.value)||0}})}
                          suffix="in" inputMode="decimal"
                          onKeyDown={(e)=>nudger(e,0.0625,(v)=>Number(v)||0)}
                          />
                 </Field>
               </div>
               <div className="col-span-6 md:col-span-3">
                 <Field label="Bleed" hint="in">
                   <Input value={line.bleedIN||0.125}
                          onChange={(e)=>onChange({...line, bleedIN:Number(e.target.value)||0})}
                          suffix="in" inputMode="decimal"
                          onKeyDown={(e)=>nudger(e,0.0625,(v)=>Number(v)||0)}
                          />
                 </Field>
               </div>
               <div className="col-span-6 md:col-span-3">
                 <Field label="Gutter" hint="in">
                   <Input value={line.gutterIN||0.125}
                          onChange={(e)=>onChange({...line, gutterIN:Number(e.target.value)||0})}
                          suffix="in" inputMode="decimal"
                          onKeyDown={(e)=>nudger(e,0.0625,(v)=>Number(v)||0)}
                          />
                 </Field>
               </div>
               {invalidSize && <div className="col-span-12 text-[11px] text-rose-600">Enter a valid piece size (W×H &gt; 0).</div>}
             </div>
 
             {/* Finishing chooser with cost preview */}
             <div className="grid grid-cols-12 gap-2 md:gap-3">
               <div className="col-span-12">
                 <div className={TOK.secTitle}>Finishing</div>
                 <div className="mt-1 grid sm:grid-cols-2 gap-2">
                   {FINISHING.map(step=>{
                     const checked = (line.finishingStepIds||[]).includes(step.id);
                     const stepCost = (step.setupMinutes/60)*DEVICE.overheadPerHour + step.costPerUnit*(line.qty||0);
                     return (
                       <label key={step.id} className="border rounded-md p-2 flex items-center justify-between">
                         <span className="flex items-center gap-2">
                           <input type="checkbox" className="accent-indigo-600" checked={checked}
                                  onChange={(e)=>{
                                    const next = new Set(line.finishingStepIds||[]);
                                    e.target.checked ? next.add(step.id) : next.delete(step.id);
                                    onChange({...line, finishingStepIds:[...next]});
                                  }}/>
                           <span className="text-sm">{step.name}</span>
                         </span>
                         <span className="text-[12px] text-stone-600">${stepCost.toFixed(2)}</span>
                       </label>
                     );
                   })}
                 </div>
                 <div className="mt-1 text-[12px] text-stone-700">Finishing total: <span className="font-semibold">${costs.finishingCost.toFixed(2)}</span></div>
               </div>
             </div>
           </div>
 
           {/* Right: diagram */}
           <div className="md:col-span-2 justify-self-start">
             <LayoutDiagram
               compact={true}
               line={{...line, _onChangeRotate:(checked)=>onChange({...line, allowRotate:checked})}}
             />
           </div>
         </div>
       </Section>
 
       {/* Pricing */}
       <Section title="Pricing" subtitle="Adjust margin, then pick a break">
         <div className="grid grid-cols-12 md:gap-3 gap-2 items-end">
           <div className="col-span-6 md:col-span-10"></div>
           <div className="col-span-6 md:col-span-2">
             <Field label="Margin %">
               {/* A2: live unit price pill + guardrail */}
               <div className="flex items-center gap-2">
                 <Input inputMode="decimal" value={Math.round((line.marginPct||0)*100)} onChange={(e)=>onChange({...line, marginPct: (Number(e.target.value)||0)/100})} suffix="%"/>
                 <span className={`inline-flex items-center px-2 h-8 rounded-md border text-xs ${ (line.marginPct||0) < 0.35 ? 'border-rose-300 text-rose-700 bg-rose-50' : 'border-stone-300 text-stone-700 bg-stone-50'}`}>
                   {priceDisabled ? '—/ea' : `${money(costs.sell/(line.qty||1))}/ea`}
                 </span>
               </div>
               {(line.marginPct||0) < 0.35 && <div className="mt-1 text-[11px] text-rose-600">Below 35% margin</div>}
             </Field>
           </div>
         </div>
 
         <div className="mt-2">
           <div className={TOK.label}>Unit price by quantity</div>
           <div className="grid grid-cols-3 sm:grid-cols-4 md:grid-cols-5 lg:grid-cols-6 gap-2">
             {qtys.map(q=>{
               const preview = computeLineCosts({ ...line, qty:q });
               const unit = preview.sell / q;
               const active = q===line.qty;
               return (
                 <button key={q} onClick={()=>onChange({...line, qty:q})}
                   className={`${TOK.chip} ${active?"bg-indigo-600 text-white border-indigo-600":"bg-white border-stone-300 hover:bg-stone-50"}`}>
                   <div className="text-[10px] opacity-80">{q} qty</div>
                   <div className="text-sm font-semibold">{money(unit)}</div>
                   {/* A3: total under each chip */}
                   <div className="text-[10px] opacity-80">{money(preview.sell)} total</div>
                 </button>
               );
             })}
           </div>
           {/* A1: collapsible Cost Breakdown */}
           <details className="mt-3">
             <summary className="cursor-pointer text-sm text-stone-700">Cost breakdown</summary>
             {(() => { const c = computeLineCosts(line); return (
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
-  const [inventory]=useState(()=>{
-    const inv=loadInventory();
-  /* Header fields & tax (C12, C11) */
-  const [cust,setCust]=useState(()=>localStorage.getItem("job.customer")||"");
-  const [jobTitle,setJobTitle]=useState(()=>localStorage.getItem("job.title")||"");
-  const [taxPct,setTaxPct]=useState(()=>Number(localStorage.getItem("job.taxPct")||0));
-
-    if(inv && inv.length) return inv;
-    const seeded=[
-      { sku:"SMOOTH-120C", name:"Smooth White 120# Cover", size:"13x19 in", onHand:1200, reorderAt:400 },
-      { sku:"TEXT-100",    name:"Text 100#",               size:"13x19 in", onHand:4800, reorderAt:1000 }
-    ];
-    saveInventory(seeded);
-    return seeded;
-  });
+  const [inventory]=useState(()=>{
+    const inv=loadInventory();
+    if(inv && inv.length) return inv;
+    const seeded=[
+      { sku:"SMOOTH-120C", name:"Smooth White 120# Cover", size:"13x19 in", onHand:1200, reorderAt:400 },
+      { sku:"TEXT-100",    name:"Text 100#",               size:"13x19 in", onHand:4800, reorderAt:1000 }
+    ];
+    saveInventory(seeded);
+    return seeded;
+  });
+  /* Header fields & tax (C12, C11) */
+  const [cust,setCust]=useState(()=>localStorage.getItem("job.customer")||"");
+  const [jobTitle,setJobTitle]=useState(()=>localStorage.getItem("job.title")||"");
+  const [taxPct,setTaxPct]=useState(()=>Number(localStorage.getItem("job.taxPct")||0));
 
   const [lines,setLines]=useState(()=>{
     const p=presets[0];
     const inv=loadInventory().find(x=>x.sku===p?.defaultSubstrate);
     const invSz = inv?parseSizeInches(inv.size):null;
     const fb = p ? findSubstrateFallback(p.defaultSubstrate||"SMOOTH-120C").size : SUBSTRATES[0].size;
@@
   return (
     <div className="mx-auto max-w-7xl md:pl-20 px-4 md:px-8 grid grid-cols-1 lg:grid-cols-[1fr,18rem] gap-6 items-start">
       <div className="space-y-4">
         {/* Customer / Job Title header (C12) */}
         <div className={`${TOK.card} p-4`}>
@@
         {lines.map(line=>(
           <LineCard key={line.id}
             line={line} presets={presets} inventory={loadInventory()}
             onChange={(patch)=>updateLine(line.id,patch)}
-            onDuplicate={()=>setLines(prev=>[...prev,{...line,id:crypto.randomUUID(), name: (line.name||'Copy')+' (copy)', focusName:true }])}])}
+            onDuplicate={()=>setLines(prev=>[...prev,{...line,id:crypto.randomUUID(), name: (line.name||'Copy')+' (copy)', focusName:true }])}
             onDelete={()=>setLines(prev=>prev.filter(l=>l.id!==line.id))}
           />
         ))}
         <div className="flex">
           <button className={`${TOK.btn} ${TOK.btnSec}`} onClick={()=>{
@@
       <aside className="sticky top-16 self-start">
         <div className="bg-white/95 backdrop-blur rounded-[var(--radius)] p-4 border border-stone-200 space-y-3 w-full lg:w-72">
           <div className={TOK.h2}>Totals</div>
           <div className="text-[13px] font-semibold text-stone-800">You’re quoting: <span className="text-indigo-700">{money(grand)}</span></div>
+          <div className="flex items-center justify-between text-sm">
+            <span>Tax %</span>
+            <input className="h-8 w-20 rounded-md border text-sm px-2 border-stone-300 focus:ring-2 focus:ring-indigo-300 focus:border-indigo-500"
+                   inputMode="decimal" value={taxPct}
+                   onChange={(e)=>{ const v=Number(e.target.value)||0; setTaxPct(v); localStorage.setItem("job.taxPct", String(v)); }} />
+          </div>
           <div className="flex justify-between text-sm"><span>Items</span><span>{money(totals)}</span></div>
-          <div className="border-t pt-2 flex justify-between font-semibold"><span>Grand Total</span><span>{money(grand)}</span></div> { useMemo, useState, useEffect, useRef } from "react";
+          <div className="border-t pt-2 flex justify-between font-semibold"><span>Grand Total</span><span>{money(grand)}</span></div>
+          <div className="mt-3 grid grid-cols-2 gap-2">
+            <button className={`${TOK.btn} ${TOK.btnPri}`}>Send / Preview</button>
+            <button className={`${TOK.btn} ${TOK.btnSec}`}>Convert to Job</button>
+          </div>
         </div>
       </aside>
     </div>
   );
 }
 
 /* ---------------- Presets Page (CRUD + Diagram) ---------------- */
 function PresetsPage({ presets, setPresets }){
   const [selectedId, setSelectedId] = useState(presets[0]?.id || "");
   const selected = presets.find(p=>p.id===selectedId) || null;
@@
             {/* Diagram (right of details, compact, no metrics) */}
-            <div className="justify-self-start">">
+            <div className="justify-self-start">
               {previewLine && <LayoutDiagram line={previewLine} showMetrics={false} compact={true} /> }
             </div>
           </div>
         )}
       </div>
@@
 export default function App(){
   const [route, goto] = useHashRoute();
   const [presets, setPresets] = useState(()=>loadPresetsLS());
   useEffect(()=>{ savePresetsLS(presets); }, [presets]);
 
   return (
     <div className="min-h-screen bg-stone-100 text-stone-900">
       <SidebarGlobal route={route} goto={goto}/>
       <header className={TOK.header}>
         <div className="flex items-center gap-3 md:pl-20">
           <div className="h-8 w-8 rounded-md bg-indigo-600"></div>
           <div className="font-semibold">Estimator — Prototype</div>
           <div className="text-xs text-stone-500">v0.7.19</div>
         </div>
         <TopTabs route={route} goto={goto}/>
       </header>
 
       <main className="pb-6">
         {route==="/job" && <JobPage presets={presets}/>}
         {route==="/customer" && <CustomerPage/>}
         {route==="/presets" && <PresetsPage presets={presets} setPresets={setPresets}/>}
         {route==="/inventory" && <InventoryPage/>}
       </main>
     </div>
   );
 }
*** End Patch
PATCH
