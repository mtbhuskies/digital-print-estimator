#!/usr/bin/env bash
set -euo pipefail

CSS="src/css/style.css"
HDR="src/partials/header.html"

echo "==> Backups (once)"
cp -n "$CSS" "${CSS}.bak" 2>/dev/null || true
cp -n "$HDR" "${HDR}.bak" 2>/dev/null || true

###############################################################################
# 1) Ensure a ribbon-style section header that matches the tabs.
###############################################################################
if ! grep -q '\.section-header{' "$CSS"; then
  cat >>"$CSS" <<'CSS'

/* Section header (match tabs ribbon) */
.section-header{
  background:#eef2ff;              /* like the nav ribbon */
  border:1px solid #e0e7ff;
  border-radius:12px;
  padding:.5rem .75rem;
  margin:0 0 .75rem 0;
}
.section-title{ font-weight:700; color:#0f172a; font-size:1.125rem; }
CSS
  echo "   [ok] appended .section-header styles"
else
  echo "   [skip] .section-header already present"
fi

###############################################################################
# 2) header.html tweaks
#    - Layout Diagram: h2 -> ribbon header
#    - Job Dashboard: remove the top header+button row -> ribbon header
#    - Remove ANY existing dashboard toolbars
#    - Insert ONE compact bottom-right toolbar after #dbAlerts
###############################################################################

# Layout Diagram: replace the plain <h2> with a ribbon header
perl -0777 -i -pe '
  s|<h2[^>]*>\s*Layout\s+Diagram\s*</h2>|<div class="section-header"><span class="section-title">Layout Diagram</span></div>|s
' "$HDR"

# Job Dashboard: nuke the header row that also includes buttons (lines 58–65 in repo)
perl -0777 -i -pe '
  s|<div\s+class="[^"]*\bmb-3\b[^"]*">\s*<h2[^>]*>\s*Job\s+Dashboard\s*</h2>\s*<div[^>]*>.*?</div>\s*</div>|<div class="section-header"><span class="section-title">Job Dashboard</span></div>|s
' "$HDR"

# Remove ANY other toolbar blocks that contain dashSave/dashBook/dashUndo/dashQuote (defensive dedupe)
perl -0777 -i -pe '
  s|\n\s*<div[^>]*>\s*(?:(?!</div>).)*(id="dashSave"|id="dashBook"|id="dashUndo"|id="dashQuote")(?:(?!.*/div>).)*</div>\s*||gs
' "$HDR"

# Insert ONE compact toolbar after the alerts div
perl -0777 -i -pe '
  s|(<div\s+class="mt-3\s+text-xs"\s+id="dbAlerts"></div>)|\1\n<div class="mt-3 flex gap-2 justify-end no-print">\n  <button class="rw-btn rw-btn--secondary rw-btn--sm" id="dashUndo">Undo</button>\n  <button class="rw-btn rw-btn--secondary rw-btn--sm" id="dashQuote">Quote</button>\n  <button class="rw-btn rw-btn--primary  rw-btn--sm" id="dashBook">Book</button>\n  <button class="rw-btn rw-btn--primary  rw-btn--sm" id="dashSave">Save</button>\n</div>|s
' "$HDR"

echo "==> Done. Dashboard toolbar deduped; both headers use the ribbon style."
git status --porcelain
