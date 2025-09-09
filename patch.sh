#!/usr/bin/env bash
set -euo pipefail

CSS="src/css/style.css"
HDR="src/partials/header.html"

echo "==> Backups (once)"
cp -n "$CSS" "${CSS}.bak" 2>/dev/null || true
cp -n "$HDR" "${HDR}.bak" 2>/dev/null || true

###############################################################################
# 1) Replace style.css with a clean, consistent UI layer
###############################################################################
cat >"$CSS" <<'CSS'
/* ==== PrintSmith-style Desktop UI ======================================== */
/* Tokens */
:root{
  --rw-primary:#2563eb;   /* blue-600 */
  --rw-primary-h:#1d4ed8; /* blue-700 */
  --rw-danger:#dc2626;    /* red-600 */
  --rw-danger-h:#b91c1c;  /* red-700 */
  --rw-fg:#0f172a;        /* slate-900 */
  --rw-muted:#475569;     /* slate-600 */
  --rw-border:#e2e8f0;    /* slate-200 */
  --rw-bg:#f8fafc;        /* slate-50 */
  --rw-card:#ffffff;
  --rw-radius:12px;
}

/* Base */
html,body{height:100%}
body{
  font-family: ui-sans-serif, system-ui, -apple-system, "Inter","Segoe UI",Roboto,"Helvetica Neue",Arial,"Noto Sans";
  color:var(--rw-fg);
  background:var(--rw-bg);
}
h1,h2,h3{font-weight:700}
h2{font-size:1.25rem; line-height:1.6}

/* Layout */
.container{max-width:1200px;margin:0 auto;padding:1rem}
.card{background:var(--rw-card);border-radius:var(--rw-radius);box-shadow:0 1px 2px rgba(0,0,0,.04);padding:1rem}
.card h2{margin-bottom:.75rem;border-bottom:1px solid var(--rw-border);padding-bottom:.5rem}

/* Tabs ribbon (keep .tab-button so existing JS keeps working) */
.tabs{
  display:flex;flex-wrap:wrap;gap:1.25rem;align-items:center;
  background:#eef2ff; /* indigo-100-ish ribbon */
  border:1px solid #e0e7ff; border-radius:var(--rw-radius);
  padding:.5rem .75rem; margin-bottom:1rem;
}
.tab-button{
  appearance:none;background:transparent;border:none;cursor:pointer;
  font-weight:700;color:var(--rw-muted);
  padding:.5rem .25rem;border-bottom:2px solid transparent;
}
.tab-button:hover{color:var(--rw-fg);border-bottom-color:#c7d2fe}
.tab-button.active{color:var(--rw-primary);border-bottom-color:var(--rw-primary)}
.tab-content{display:none}.tab-content.active{display:block}

/* Buttons (one shape everywhere) */
.rw-btn{
  appearance:none;display:inline-flex;align-items:center;justify-content:center;gap:.5rem;
  height:38px;padding:0 14px;border-radius:8px;border:1px solid transparent;
  font-weight:700;font-size:.875rem;line-height:1;cursor:pointer;
  transition:background-color .15s,border-color .15s,box-shadow .15s,transform .02s,opacity .15s;
  box-shadow:0 1px 2px rgba(0,0,0,.04)
}
.rw-btn:focus-visible{outline:2px solid #93c5fd; outline-offset:2px}
.rw-btn:active{transform:translateY(1px)}
.rw-btn:disabled{opacity:.6;cursor:not-allowed}
.rw-btn--primary{background:var(--rw-primary);color:#fff}
.rw-btn--primary:hover{background:var(--rw-primary-h)}
.rw-btn--secondary{background:#fff;color:var(--rw-fg);border-color:var(--rw-border)}
.rw-btn--secondary:hover{background:#f1f5f9;border-color:#cbd5e1}
.rw-btn--danger{background:var(--rw-danger);color:#fff}
.rw-btn--danger:hover{background:var(--rw-danger-h)}
.rw-btn--sm{height:34px;padding:0 12px;font-size:.8125rem;border-radius:8px}

/* Inputs */
input[type=text],input[type=number],input[type=email],input[type=tel],select,textarea{
  width:100%;height:40px;background:#fff;border:1px solid var(--rw-border);
  border-radius:8px;padding:.5rem .625rem;color:var(--rw-fg)
}
textarea{min-height:100px}
input:focus,select:focus,textarea:focus{outline:2px solid #bfdbfe;border-color:#93c5fd}

/* Layout Diagram – fill width, sensible height */
.canvas-container{
  width:100%;position:relative;
  aspect-ratio: var(--layout-ratio, 3 / 2);
  max-height:520px;min-height:220px;
  background:#f3f4f6;border-radius:12px;
}
#impositionCanvas{position:absolute;inset:0;width:100%;height:100%;
  border:1px solid var(--rw-border);border-radius:12px;pointer-events:none}

/* Misc utilities used in templates */
.flex{display:flex}.gap-2{gap:.5rem}.gap-3{gap:.75rem}.gap-4{gap:1rem}
.items-center{align-items:center}.justify-end{justify-content:flex-end}
.mt-2{margin-top:.5rem}.mt-3{margin-top:.75rem}.mb-3{margin-bottom:.75rem}
.text-xs{font-size:.75rem}.text-sm{font-size:.875rem}
.no-print{}
/* Print behavior preserved */
@media print{body *{visibility:hidden} #quote,#quote *{visibility:visible} #quote{position:absolute;inset:0;width:100%;margin:0;box-shadow:none}}
CSS
echo "   [ok] wrote $CSS"

###############################################################################
# 2) HEADER: restore clickable tabs, remove any dashboard toolbars,
#    insert a single compact toolbar at the bottom of the card
###############################################################################

# 2a) Replace the <nav> block with a clean, clickable tabs ribbon.
#     (Keep .tab-button so your JS continues to work.)
perl -0777 -i -pe '
  s|<nav\b[^>]*>.*?</nav>|<nav class="tabs no-print">
    <button class="tab-button active" data-tab="setup">Setup</button>
    <button class="tab-button" data-tab="job">Job</button>
    <button class="tab-button" data-tab="parts">Parts</button>
    <button class="tab-button" data-tab="templates">Templates</button>
    <button class="tab-button" data-tab="pricing">Pricing</button>
    <button class="tab-button" data-tab="inventory">Inventory</button>
    <button class="tab-button" data-tab="quoteTab">Quote</button>
  </nav>|s' "$HDR"

# 2b) Remove ANY existing Job Dashboard toolbars inside the heading row.
perl -0777 -i -pe '
  s|<div\s+class="[^"]*mb-3[^"]*">\s*<h2[^>]*>\s*Job\s+Dashboard\s*</h2>\s*<div[^>]*>.*?</div>\s*</div>|<h2 class="text-xl font-semibold mb-3 border-b pb-2">Job Dashboard</h2>|s
' "$HDR"

# 2c) Remove any previously-inserted bottom toolbars to dedupe.
perl -0777 -i -pe '
  s|\n\s*<div class="mt-3\s+flex[^"]*>\s*<button[^>]*id="dashSave"[\s\S]*?</div>\s*||g
' "$HDR"

# 2d) Insert ONE compact toolbar after #dbAlerts (bottom-right).
perl -0777 -i -pe '
  s|(<div class="mt-3 text-xs" id="dbAlerts"></div>)|\1\n<div class="mt-3 flex gap-2 justify-end no-print">\n  <button class="rw-btn rw-btn--secondary rw-btn--sm" id="dashUndo">Undo</button>\n  <button class="rw-btn rw-btn--secondary rw-btn--sm" id="dashQuote">Quote</button>\n  <button class="rw-btn rw-btn--primary  rw-btn--sm" id="dashBook">Book</button>\n  <button class="rw-btn rw-btn--primary  rw-btn--sm" id="dashSave">Save</button>\n</div>|s
' "$HDR"

echo "==> Done. Tabs clickable; single dashboard toolbar; clean CSS."
git status --porcelain
