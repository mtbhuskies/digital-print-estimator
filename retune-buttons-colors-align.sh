#!/usr/bin/env bash
set -euo pipefail

# Files
HTML="src/index.template.html"                       # not changed here, kept for reference
HEADER="src/partials/header.html"
SETUP="src/partials/tabs_setup.html"
JOB="src/partials/tabs_job.html"
INV="src/partials/tabs_inventory.html"
PRICE="src/partials/tabs_pricing.html"
TPL="src/partials/tabs_templates.html"
PARTS="src/partials/tabs_parts.html"

# Helpers
# Replace class=... on BUTTON by id=... (handles id before/after class)
rb_id() {
  local f="$1" id="$2" klass="$3"
  # id before class
  perl -0777 -i -pe "s/(<button\b[^>]*\\bid=\"$id\"[^>]*\\bclass=\")[^\"]*(\"[^>]*>)/\${1}$klass\${2}/g" "$f"
  # class before id
  perl -0777 -i -pe "s/(<button\b[^>]*\\bclass=\")[^\"]*(\"[^>]*\\bid=\"$id\"[^>]*>)/\${1}$klass\${2}/g" "$f"
}

# Replace class=... on LABEL by visible text (exact, leading spaces ok)
rb_label_text() {
  local f="$1" text="$2" klass="$3"
  perl -0777 -i -pe "s/(<label\b[^>]*\\bclass=\")[^\"]*(\"[^>]*>\\s*$text\\b)/\${1}$klass\${2}/g" "$f"
}

# Add a class token to a specific container class value (exact match on the whole class attribute string)
add_class_exact() {
  local f="$1" old="$2" add="$3"
  perl -0777 -i -pe "s/(class=\")$old(\")/\${1}$old $add\${2}/g" "$f"
}

echo "[1/3] Right-justify button containers…"

# Header bars
add_class_exact "$HEADER" "flex gap-2 no-print" "justify-end"
add_class_exact "$HEADER" "mt-2 flex items-center gap-2" "justify-end"
add_class_exact "$HEADER" "flex gap-2" "justify-end"  # dashboard row in header.html

# Setup tab
add_class_exact "$SETUP" "mt-3 flex items-center gap-2" "justify-end"

# Job tab
add_class_exact "$JOB" "col-span-2 flex gap-2" "justify-end"

# Pricing tab
add_class_exact "$PRICE" "flex gap-2 no-print" "justify-end"

# Templates tab
add_class_exact "$TPL" "mt-3 flex gap-2" "justify-end"

# Parts tab
add_class_exact "$PARTS" "flex gap-2 items-center" "justify-end"

echo "[2/3] Recolor buttons by intent…"

# HEADER
rb_id "$HEADER" "btnExportEstimate"     "rw-btn rw-btn--positive"
rb_id "$HEADER" "btnPrintQuote"         "rw-btn rw-btn--secondary"
rb_id "$HEADER" "btnAddTemplate"        "hidden rw-btn rw-btn--secondary"

# Header dashboard mini-buttons
rb_id "$HEADER" "dashSave"              "rw-btn rw-btn--secondary text-xs"
rb_id "$HEADER" "dashBook"              "rw-btn rw-btn--positive text-xs"
rb_id "$HEADER" "dashUndo"              "rw-btn rw-btn--danger   text-xs"
rb_id "$HEADER" "dashQuote"             "rw-btn rw-btn--secondary text-xs"

# SETUP
rb_label_text "$SETUP" "Upload Logo"    "rw-btn rw-btn--secondary cursor-pointer"
rb_id "$SETUP" "btnProfileSave"         "rw-btn rw-btn--positive"

# JOB
rb_id "$JOB" "btnSaveCustomerFromJob"   "rw-btn rw-btn--positive"
rb_id "$JOB" "btnDeleteCustomerFromJob" "rw-btn rw-btn--danger"

# INVENTORY (grid; right-justify each with justify-self-end)
rb_id "$INV" "btnInvAdd"                "rw-btn rw-btn--positive justify-self-end"
rb_id "$INV" "btnInvClear"              "rw-btn rw-btn--danger   justify-self-end"
rb_id "$INV" "btnCatOpen"               "rw-btn rw-btn--secondary justify-self-end"
rb_id "$INV" "btnCatAdd"                "rw-btn rw-btn--positive justify-self-end"
rb_id "$INV" "btnCatExport"             "rw-btn rw-btn--secondary justify-self-end"
rb_label_text "$INV" "Import CSV"       "rw-btn rw-btn--secondary cursor-pointer text-center justify-self-end"
rb_id "$INV" "btnCatClear"              "rw-btn rw-btn--danger justify-self-end"

# PRICING
rb_id "$PRICE" "btnRecalc"              "rw-btn rw-btn--secondary"
rb_id "$PRICE" "btnBook"                "rw-btn rw-btn--positive"
rb_id "$PRICE" "btnUndoBooking"         "rw-btn rw-btn--danger"

# TEMPLATES
rb_id "$TPL" "btnTplSave"               "rw-btn rw-btn--positive"
rb_id "$TPL" "btnTplUpdate"             "rw-btn rw-btn--positive hidden"
rb_id "$TPL" "btnTplDelete"             "rw-btn rw-btn--danger hidden"
rb_id "$TPL" "btnTplClear"              "rw-btn rw-btn--secondary"

# PARTS
rb_id "$PARTS" "btnAddPart"             "rw-btn rw-btn--positive"
rb_id "$PARTS" "btnRemovePart"          "rw-btn rw-btn--danger"

echo "[3/3] Done. Preview:"
git status --porcelain
