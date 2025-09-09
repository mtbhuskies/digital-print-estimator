#!/usr/bin/env bash
set -euo pipefail

CSS="src/css/style.css"
HDR="src/partials/header.html"

echo "==> Backups (once)"
cp -n "$CSS" "${CSS}.bak" 2>/dev/null || true
cp -n "$HDR" "${HDR}.bak" 2>/dev/null || true

###############################################################################
# 1) Ensure ribbon header style (matches the tabs ribbon look)
###############################################################################
if ! grep -q '\.section-header{' "$CSS"; then
  cat >>"$CSS" <<'CSS'

/* Section header (ribbon) */
.section-header{
  background:#eef2ff;              /* light indigo ribbon */
  border:1px solid #e0e7ff;        /* indigo-200 */
  border-radius:12px;
  padding:.5rem .75rem;
  margin:0 0 .75rem 0;
}
.section-title{ font-weight:700; color:#0f172a; font-size:1.125rem; }
CSS
  echo "   [ok] added .section-header"
else
  echo "   [skip] .section-header already present"
fi

###############################################################################
# 2) header.html — fix Job Dashboard
###############################################################################

# 2a) Replace the old top header+button row with a ribbon header.
#     (This block starts at lines 58–65 in your repo today.)
perl -0777 -i -pe '
  s|<div\s+class="[^"]*\bmb-3\b[^"]*">\s*<h2[^>]*>\s*Job\s+Dashboard\s*</h2>\s*<div[^>]*>.*?</div>\s*</div>|<div class="section-header"><span class="section-title">Job Dashboard</span></div>|s
' "$HDR"

# 2b) Remove ANY existing toolbar blocks containing dashSave/dashBook/dashUndo/dashQuote (defensive dedupe).
perl -0777 -i -pe '
  s|\n\s*<div[^>]*>\s*(?:(?!</div>).)*(id="dashSave"|id="dashBook"|id="dashUndo"|id="dashQuote")(?:(?!.*/div>).)*</div>\s*||gs
' "$HDR"

# 2c) Insert ONE compact toolbar at the bottom, after the alerts div.
perl -0777 -i -pe '
  s|(<div\s+class="mt-3\s+text-xs"\s+id="dbAlerts"></div>)|\1\n<div class="mt-3 flex gap-2 justify-end no-print">\n  <button class="rw-btn rw-btn--secondary rw-btn--sm" id="dashUndo">Undo</button>\n  <button class="rw-btn rw-btn--secondary rw-btn--sm" id="dashQuote">Quote</button>\n  <button class="rw-btn rw-btn--positive  rw-btn--sm" id="dashBook">Book</button>\n  <button class="rw-btn rw-btn--positive  rw-btn--sm" id="dashSave">Save</button>\n</div>|s
' "$HDR"

echo "==> Done. Job Dashboard now uses the ribbon header; single bottom toolbar only."
git status --porcelain
