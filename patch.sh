#!/usr/bin/env bash
set -euo pipefail

CSS="src/css/style.css"
HDR="src/partials/header.html"

echo "==> Backups (once)"
cp -n "$CSS" "${CSS}.bak" 2>/dev/null || true
cp -n "$HDR" "${HDR}.bak" 2>/dev/null || true

###############################################################################
# 1) Add a section header style that matches the tabs' tinted ribbon.
###############################################################################
if ! grep -q '\.section-header{' "$CSS"; then
  cat >>"$CSS" <<'CSS'

/* Section header (match tabs ribbon) */
.section-header{
  background:#eef2ff;                /* indigo-100-ish, like the tabs */
  border:1px solid #e0e7ff;          /* indigo-200 */
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
# 2) HEADER.HTML fixes
#    - Replace mixed header rows with unified .section-header for BOTH cards
#    - Remove ANY existing dashboard toolbars
#    - Insert ONE compact toolbar after #dbAlerts (bottom-right)
###############################################################################

# 2a) Layout Diagram: h2 -> section-header
#     (Was at ~L47–L54)  :contentReference[oaicite:0]{index=0}
perl -0777 -i -pe '
  s|<h2[^>]*>\s*Layout\s+Diagram\s*</h2>|<div class="section-header"><span class="section-title">Layout Diagram</span></div>|s
' "$HDR"

# 2b) Job Dashboard: delete the top header row that also holds buttons and replace with section-header
#     (Was at ~L58–L66)  :contentReference[oaicite:1]{index=1}
perl -0777 -i -pe '
  s|<div\s+class="[^"]*\bmb-3\b[^"]*">\s*<h2[^>]*>\s*Job\s+Dashboard\s*</h2>\s*<div[^>]*>.*?</div>\s*</div>|<div class="section-header"><span class="section-title">Job Dashboard</span></div>|s
' "$HDR"

# 2c) Nuke ANY existing dashboard toolbars (defensive dedupe).
#     Removes any <div> that contains dashSave/dashBook/dashUndo/dashQuote.
perl -0777 -i -pe '
  s|\n\s*<div[^>]*>\s*(?:(?!</div>).)*(id="dashSave"|id="dashBook"|id="dashUndo"|id="dashQuote")(?:(?!.*/div>).)*</div>\s*||gs
' "$HDR"

# 2d) Insert ONE compact toolbar after the alerts block inside the dashboard section.
#     Alerts block is present here:  :contentReference[oaicite:2]{index=2}
perl -0777 -i -pe '
  s|(<div\s+class="mt-3\s+text-xs"\s+id="dbAlerts"></div>)|\1\n<div class="mt-3 flex gap-2 justify-end no-print">\n  <button class="rw-btn rw-btn--secondary rw-btn--sm" id="dashUndo">Undo</button>\n  <button class="rw-btn rw-btn--secondary rw-btn--sm" id="dashQuote">Quote</button>\n  <button class="rw-btn rw-btn--primary  rw-btn--sm" id="dashBook">Book</button>\n  <button class="rw-btn rw-btn--primary  rw-btn--sm" id="dashSave">Save</button>\n</div>|s
' "$HDR"

echo "==> Done. Headers unified; dashboard toolbar deduped."
git status --porcelain
