#!/usr/bin/env bash
set -euo pipefail

HDR="src/partials/header.html"
CSS="src/css/style.css"

# backups
cp -n "$HDR" "${HDR}.bak" 2>/dev/null || true
cp -n "$CSS" "${CSS}.bak" 2>/dev/null || true

# ensure ribbon styles exist
if ! grep -q '\.section-header{' "$CSS"; then
  cat >>"$CSS" <<'CSS'
.section-header{background:#eef2ff;border:1px solid #e0e7ff;border-radius:12px;padding:.5rem .75rem;margin:0 0 .75rem 0}
.section-title{font-weight:700;color:#0f172a;font-size:1.125rem}
CSS
fi

# 1) Job Dashboard header -> ribbon
perl -0777 -i -pe '
  s|<h2[^>]*>\s*Job\s+Dashboard\s*</h2>|<div class="section-header"><span class="section-title">Job Dashboard</span></div>|s
' "$HDR"

# 2) Remove ALL existing dashboard toolbars (covers duplicates now and later)
perl -0777 -i -pe '
  s|\n\s*<div[^>]*class="[^"]*\bmt-3\b[^"]*\bflex\b[^"]*"[^>]*>\s*(?:(?!</div>).)*(?:id="dashUndo"|id="dashQuote"|id="dashBook"|id="dashSave")(?:.|\n)*?</div>\s*||gs
' "$HDR"

# 3) Add ONE canonical bottom toolbar after the alerts block
perl -0777 -i -pe '
  s|(<div\s+class="mt-3\s+text-xs"\s+id="dbAlerts"></div>)|\1\n<div class="mt-3 flex gap-2 justify-end no-print">\n  <button class="rw-btn rw-btn--secondary rw-btn--sm" id="dashUndo">Undo</button>\n  <button class="rw-btn rw-btn--secondary rw-btn--sm" id="dashQuote">Quote</button>\n  <button class="rw-btn rw-btn--positive  rw-btn--sm" id="dashBook">Book</button>\n  <button class="rw-btn rw-btn--positive  rw-btn--sm" id="dashSave">Save</button>\n</div>|s
' "$HDR"

echo "Fixed: single dashboard toolbar + ribbon header."
