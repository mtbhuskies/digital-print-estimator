#!/usr/bin/env bash
set -euo pipefail

# 1) Append unified button CSS once
CSS_FILE="src/css/style.css"
if ! grep -q '\.rw-btn' "$CSS_FILE"; then
  cat >>"$CSS_FILE" <<'CSS'
/* --- Unified Buttons ----------------------------------------------------- */
:root{
  --rw-btn-h: 40px;
  --rw-btn-px: 16px;
  --rw-btn-gap: 8px;
  --rw-btn-radius: 10px;
  --rw-btn-weight: 600;
  --rw-btn-fs: 0.875rem; /* ~text-sm */

  /* Map to your palette if you like; these match existing emerald/rose */
  --rw-positive: #059669;       /* emerald-600 */
  --rw-positive-hover: #047857; /* emerald-700 */
  --rw-danger: #e11d48;         /* rose-600 */
  --rw-danger-hover: #be123c;   /* rose-700 */

  --rw-neutral-fg: #111827;
  --rw-neutral-bg: #ffffff;
  --rw-neutral-border: #d1d5db;
  --rw-on-dark: #ffffff;
  --rw-focus: rgba(15,23,42,.7); /* slate-ish */
}

.rw-btn{
  appearance:none; display:inline-flex; align-items:center; justify-content:center; gap:var(--rw-btn-gap);
  height:var(--rw-btn-h); padding:0 var(--rw-btn-px);
  border-radius:var(--rw-btn-radius); border:1px solid transparent;
  font-weight:var(--rw-btn-weight); font-size:var(--rw-btn-fs); line-height:1;
  cursor:pointer; user-select:none; text-decoration:none;
  transition:background-color .15s, border-color .15s, box-shadow .15s, transform .02s, opacity .15s;
  box-shadow: 0 1px 2px rgba(0,0,0,.05);
}
.rw-btn:focus-visible{ outline:2px solid var(--rw-focus); outline-offset:2px; }
.rw-btn:active{ transform: translateY(1px); }
.rw-btn:disabled{ opacity:.6; cursor:not-allowed; }

.rw-btn--positive{ background:var(--rw-positive); color:var(--rw-on-dark); }
.rw-btn--positive:hover:not(:disabled){ background:var(--rw-positive-hover); }

.rw-btn--danger{ background:var(--rw-danger); color:var(--rw-on-dark); }
.rw-btn--danger:hover:not(:disabled){ background:var(--rw-danger-hover); }

.rw-btn--secondary{
  background:var(--rw-neutral-bg); color:var(--rw-neutral-fg); border-color:var(--rw-neutral-border);
}
.rw-btn--secondary:hover:not(:disabled){ background:#f9fafb; border-color:#cbd5e1; }

.rw-btn .rw-icon{ width:18px; height:18px; flex:0 0 auto; color:currentColor; }
CSS
  echo "[ok] appended .rw-btn CSS to $CSS_FILE"
else
  echo "[skip] $CSS_FILE already has .rw-btn"
fi

# Helper: replace class attr on a <button> by id (works regardless of attr order)
# args: file id newClass
rb_id() {
  local f="$1" id="$2" klass="$3"
  # id before class
  perl -0777 -i -pe "s/(<button\b[^>]*\\bid=\"$id\"[^>]*\\bclass=\")[^\"]*(\"[^>]*>)/\${1}$klass\${2}/g" "$f"
  # class before id
  perl -0777 -i -pe "s/(<button\b[^>]*\\bclass=\")[^\"]*(\"[^>]*\\bid=\"$id\"[^>]*>)/\${1}$klass\${2}/g" "$f"
}

# Helper: replace class attr on a <label> by visible text content (Import CSV / Upload Logo)
# args: file visible_text newClass
rb_label_text() {
  local f="$1" text="$2" klass="$3"
  perl -0777 -i -pe "s/(<label\b[^>]*\\bclass=\")[^\"]*(\"[^>]*>\\s*$text\\b)/\${1}$klass\${2}/g" "$f"
}

HTML="src/index.template.html"
HEADER="src/partials/header.html"
SETUP="src/partials/tabs_setup.html"
JOB="src/partials/tabs_job.html"
INV="src/partials/tabs_inventory.html"
PRICE="src/partials/tabs_pricing.html"
TPL="src/partials/tabs_templates.html"
PARTS="src/partials/tabs_parts.html"

# 2) Remove inline <style id="unified-buttons">…</style> block
perl -0777 -i -pe 's#\n\s*<style id="unified-buttons">.*?</style>\s*\n#\n  <!-- unified-buttons removed; using .rw-btn in css/style.css -->\n#s' "$HTML"
echo "[ok] removed inline #unified-buttons from $HTML"

# 3) Header actions & dashboard
rb_id "$HEADER" "btnExportEstimate" "rw-btn rw-btn--positive"
rb_id "$HEADER" "btnPrintQuote" "rw-btn rw-btn--positive"
rb_id "$HEADER" "btnAddTemplate" "hidden rw-btn rw-btn--positive"
rb_id "$HEADER" "dashSave" "rw-btn rw-btn--positive"
rb_id "$HEADER" "dashBook" "rw-btn rw-btn--positive"
rb_id "$HEADER" "dashUndo" "rw-btn rw-btn--secondary"
rb_id "$HEADER" "dashQuote" "rw-btn rw-btn--positive"

# 4) Setup
rb_label_text "$SETUP" "Upload Logo" "rw-btn rw-btn--secondary cursor-pointer"
rb_id "$SETUP" "btnProfileSave" "rw-btn rw-btn--positive"

# 5) Job
rb_id "$JOB" "btnSaveCustomerFromJob" "rw-btn rw-btn--positive"
rb_id "$JOB" "btnDeleteCustomerFromJob" "rw-btn rw-btn--danger"

# 6) Inventory
rb_id "$INV" "btnInvAdd" "rw-btn rw-btn--positive"
rb_id "$INV" "btnInvClear" "rw-btn rw-btn--danger"
rb_id "$INV" "btnCatOpen" "rw-btn rw-btn--secondary"
rb_id "$INV" "btnCatAdd" "rw-btn rw-btn--positive"
rb_id "$INV" "btnCatExport" "rw-btn rw-btn--secondary"
rb_label_text "$INV" "Import CSV" "rw-btn rw-btn--secondary cursor-pointer text-center"
rb_id "$INV" "btnCatClear" "rw-btn rw-btn--danger"

# 7) Pricing
rb_id "$PRICE" "btnRecalc" "rw-btn rw-btn--positive"
rb_id "$PRICE" "btnBook" "rw-btn rw-btn--positive"
rb_id "$PRICE" "btnUndoBooking" "rw-btn rw-btn--secondary"

# 8) Templates
rb_id "$TPL" "btnTplSave" "rw-btn rw-btn--positive"
rb_id "$TPL" "btnTplUpdate" "rw-btn rw-btn--positive hidden"
rb_id "$TPL" "btnTplDelete" "rw-btn rw-btn--danger hidden"
rb_id "$TPL" "btnTplClear" "rw-btn rw-btn--danger"

# 9) Parts
rb_id "$PARTS" "btnAddPart" "rw-btn rw-btn--positive"
rb_id "$PARTS" "btnRemovePart" "rw-btn rw-btn--danger"

echo "[done] unified buttons applied"
echo
git status --porcelain
