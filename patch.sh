#!/usr/bin/env bash
set -euo pipefail

HDR="src/partials/header.html"
CSS="src/css/style.css"

# one-time backups
cp -n "$HDR" "${HDR}.bak" 2>/dev/null || true
cp -n "$CSS" "${CSS}.bak" 2>/dev/null || true

# Ensure ribbon styles exist (already present in your repo, but keep idempotent)
if ! grep -q '\.section-header{' "$CSS"; then
  cat >>"$CSS" <<'CSS'
/* Section header (ribbon) */
.section-header{background:#eef2ff;border:1px solid #e0e7ff;border-radius:12px;padding:.5rem .75rem;margin:0 0 .75rem 0}
.section-title{font-weight:700;color:#0f172a;font-size:1.125rem}
CSS
fi

# 1) Replace the plain <h2> Job Dashboard header with the ribbon header
perl -0777 -i -pe '
  s|<h2\s+class="[^"]*">\s*Job\s+Dashboard\s*</h2>|<div class="section-header"><span class="section-title">Job Dashboard</span></div>|s
' "$HDR"

# 2) Remove ALL existing toolbars that include dash* buttons (handles any duplicates)
perl -0777 -i -pe '
  s|\n\s*<div[^>]*class="[^"]*mt-3[^"]*\bflex\b[^"]*"[^>]*>\s*(?:(?!</div>).)*(?:id="dashUndo"|id="dashQuote"|id="dashBook"|id="dashSave")(?:.|\n)*?</div>\s*||gs
' "$HDR"

# 3) Insert ONE compact toolbar after the alerts div
perl -0777 -i -pe '
  s|(<div\s+class="mt-3\s+text-xs"\s+id="dbAlerts"></div>)|\1\n<div class="mt-3 flex gap-2 justify-end no-print">\n  <button class="rw-btn rw-btn--secondary rw-btn--sm" id="dashUndo">Undo</button>\n  <button class="rw-btn rw-btn--secondary rw-btn--sm" id="dashQuote">Quote</button>\n  <button class="rw-btn rw-btn--primary  rw-btn--sm" id="dashBook">Book</button>\n  <button class="rw-btn rw-btn--primary  rw-btn--sm" id="dashSave">Save</button>\n</div>|s
' "$HDR"

echo "Fixed: ribbon header + single bottom toolbar."
