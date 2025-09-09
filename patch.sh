# fix-dashboard.sh
#!/usr/bin/env bash
set -euo pipefail

CSS="src/css/style.css"
HDR="src/partials/header.html"

# 1) Ensure a small button size exists
if ! grep -q '\.rw-btn--sm' "$CSS"; then
  cat >>"$CSS" <<'CSS'

/* compact toolbar buttons */
.rw-btn--sm{ height:34px; padding:0 12px; font-size:.8125rem; border-radius:8px }
CSS
  echo "[ok] added .rw-btn--sm to $CSS"
fi

# 2) Replace the entire Job Dashboard section with a clean, single-toolbar version
perl -0777 -i -pe '
  s|
  <section\b[^>]*\bid="dashboard"[^>]*>.*?</section>
  |<section class="bg-white p-4 rounded-xl shadow" id="dashboard" style="margin-top:0">
     <h2 class="text-xl font-semibold mb-3 border-b pb-2">Job Dashboard</h2>

     <div class="grid grid-cols-2 gap-2 text-sm">
       <div class="rounded-lg bg-slate-50 p-2 text-center"><div class="text-xs text-gray-500">Cost</div><div class="text-lg font-semibold" id="dbCost">—</div></div>
       <div class="rounded-lg bg-slate-50 p-2 text-center"><div class="text-xs text-gray-500">Sell</div><div class="text-lg font-semibold" id="dbSell">—</div></div>
       <div class="rounded-lg bg-slate-50 p-2 text-center"><div class="text-xs text-gray-500">Profit</div><div class="text-lg font-semibold" id="dbProfit">—</div></div>
       <div class="rounded-lg bg-slate-50 p-2 text-center"><div class="text-xs text-gray-500">Margin</div><div class="text-lg font-semibold" id="dbMargin">—</div></div>
     </div>

     <div class="mt-3">
       <div class="text-sm font-semibold mb-1">Parts Overview</div>
       <table class="w-full text-xs">
         <thead class="text-left text-gray-600"><tr>
           <th class="py-1 pr-2">Part</th>
           <th class="py-1 pr-2 text-right">Ups</th>
           <th class="py-1 pr-2 text-right">Sheets</th>
           <th class="py-1 pr-2 text-right">Paper</th>
           <th class="py-1 pr-2 text-right">Press</th>
         </tr></thead>
         <tbody id="dbParts"></tbody>
       </table>
     </div>

     <div class="mt-3 text-xs" id="dbAlerts"></div>

     <!-- single toolbar (small, bottom-right) -->
     <div class="mt-3 flex gap-2 justify-end no-print">
       <button class="rw-btn rw-btn--secondary rw-btn--sm" id="dashUndo">Undo</button>
       <button class="rw-btn rw-btn--secondary rw-btn--sm" id="dashQuote">Quote</button>
       <button class="rw-btn rw-btn--positive  rw-btn--sm" id="dashBook">Book</button>
       <button class="rw-btn rw-btn--positive  rw-btn--sm" id="dashSave">Save</button>
     </div>
   </section>
  |gsx;
' "$HDR"

echo "[done] Dashboard repaired (single toolbar, layout restored)."
