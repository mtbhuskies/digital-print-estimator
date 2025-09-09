#!/usr/bin/env bash
set -euo pipefail

HDR="src/partials/header.html"

# 1) Remove the original top toolbar next to "Job Dashboard" (keep the H2)
#    The current file has a header row with buttons at L58–L66. :contentReference[oaicite:0]{index=0}
perl -0777 -i -pe '
  s|
    <div\s+class="flex\s+items-center\s+justify-between\s+mb-3">\s*
    <h2[^>]*>Job\s+Dashboard</h2>\s*
    <div\s+class="flex\s+gap-2">.*?</div>\s*
    </div>
  |<div class="flex items-center justify-between mb-3">\n  <h2 class="text-xl font-semibold">Job Dashboard</h2>\n</div>|gsx
' "$HDR"

# 2) Remove ANY previously-inserted dashboard toolbars (defensive dedupe)
perl -0777 -i -pe '
  s|\n\s*<div[^>]*>\s*<button[^>]*id="dashSave"[^>]*>.*?</div>\s*||gs;   # generic block that contains dashSave
' "$HDR"

# 3) Insert one right-aligned toolbar AFTER the alerts div (#dbAlerts)
#    Alerts div is at L25 currently. :contentReference[oaicite:1]{index=1}
perl -0777 -i -pe '
  s|
    (<div\s+class="mt-3\s+text-xs"\s+id="dbAlerts"></div>)
  |\1\n<div class="mt-3 flex gap-2 justify-end">\n  <button class="rw-btn rw-btn--secondary rw-btn--sm" id="dashSave">Save</button>\n  <button class="rw-btn rw-btn--positive  rw-btn--sm" id="dashBook">Book</button>\n  <button class="rw-btn rw-btn--danger    rw-btn--sm" id="dashUndo">Undo</button>\n  <button class="rw-btn rw-btn--secondary rw-btn--sm" id="dashQuote">Quote</button>\n</div>
  |sx
' "$HDR"

echo "[done] Deduped dashboard toolbar: only one row at the bottom remains."
git status --porcelain
