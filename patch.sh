#!/usr/bin/env bash
set -euo pipefail

INV="src/partials/tabs_inventory.html"

# Replace the three separate elements (Export, Import label, Clear) with one right-justified row.
perl -0777 -i -pe '
  s{
    \s*<button\s+class="rw-btn\s+rw-btn--secondary"\s+id="btnCatExport">Export CSV</button>\s*
    <label\s+class="rw-btn\s+rw-btn--secondary\s+cursor-pointer\s+text-center">Import\s+CSV\s*
      <input[^>]*id="catImport"[^>]*>\s*
    </label>\s*
    <button\s+class="rw-btn\s+rw-btn--danger"\s+id="btnCatClear">Clear Catalog</button>
  }{
    \n  <div class="col-span-4 flex gap-2 justify-end">\n    <button class="rw-btn rw-btn--secondary" id="btnCatExport">Export CSV</button>\n    <label class="rw-btn rw-btn--secondary cursor-pointer text-center">Import CSV\n      <input accept=".csv" class="hidden" id="catImport" type="file"/>\n    </label>\n    <button class="rw-btn rw-btn--danger" id="btnCatClear">Clear Catalog</button>\n  </div>
  }sx' "$INV"

echo "[ok] Moved Export/Import/Clear into one right-aligned row in $INV"
git status --porcelain
