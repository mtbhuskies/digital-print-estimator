#!/usr/bin/env bash
set -euo pipefail

INV="src/partials/tabs_inventory.html"

# If the unified row already exists, do nothing.
if grep -q 'col-span-4 flex gap-2 justify-end' "$INV"; then
  echo "[skip] unified actions row already present in $INV"
  exit 0
fi

# Replace the three separate controls with a single right-aligned row.
perl -0777 -i -pe '
  s{
    \s*<button\b[^>]*\bid="btnCatExport"[^>]*>.*?</button>\s*
    <label\b[^>]*>\s*Import\s*CSV\b.*?id="catImport"[^>]*>.*?</label>\s*
    <button\b[^>]*\bid="btnCatClear"[^>]*>.*?</button>
  }{
    \n  <div class="col-span-4 flex gap-2 justify-end">\n    <button class="rw-btn rw-btn--secondary" id="btnCatExport">Export CSV</button>\n    <label class="rw-btn rw-btn--secondary cursor-pointer text-center">Import CSV\n      <input accept=".csv" class="hidden" id="catImport" type="file"/>\n    </label>\n    <button class="rw-btn rw-btn--danger" id="btnCatClear">Clear Catalog</button>\n  </div>
  }gsx' "$INV"

echo "[ok] Export/Import/Clear moved into one right-aligned row in $INV"
git status --porcelain
