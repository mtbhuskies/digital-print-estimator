#!/usr/bin/env bash
set -euo pipefail

CSS="src/css/style.css"
HDR="src/partials/header.html"

# 1) style.css — unify buttons, add small size, keep tabs underline, add tabs ribbon helper.
#    - primary -> BLUE
#    - radius -> 8px
#    - add .rw-btn--sm
#    - add .tabs-bar style (light ribbon)
perl -0777 -i -pe '
  s/--rw-btn-radius:\s*10px;/--rw-btn-radius: 8px;/;
  s/--rw-positive:\s*#059669;.*?\n/--rw-positive: #2563eb;       \/* blue-600 *\/\n/;
  s/--rw-positive-hover:\s*#047857;.*?\n/--rw-positive-hover: #1d4ed8; \/* blue-700 *\/\n/;
  # add .rw-btn--sm if missing
  if (!/\.rw-btn--sm\{/s) {
    $_ .= "\n/* small buttons for dense toolbars */\n.rw-btn--sm{ --rw-btn-h:34px; --rw-btn-px:12px; --rw-btn-fs:.8125rem; --rw-btn-radius:8px; }\n.rw-btn--sm .rw-icon{ width:16px; height:16px; }\n";
  }
  # add .tabs-bar ribbon if missing
  if (!/\.tabs-bar\{/s) {
    $_ .= "\n/* tabs ribbon */\n.tabs-bar{ background:#eff6ff; border-bottom:1px solid #dbeafe; border-top-left-radius:.75rem; border-top-right-radius:.75rem; padding:.5rem; margin:-1rem -1rem 1rem; }\n";
  }
' "$CSS"

# 2) header.html — keep clickability, add ribbon, unify headers, move & dedupe toolbar.

# 2a) Tabs row: add tabs-bar class to nav (preserve existing classes)
perl -0777 -i -pe '
  s/<nav class="([^"]*?)border-b([^"]*?)">/<nav class="tabs-bar \1border-b\2">/;
' "$HDR"

# 2b) Job Dashboard header: replace the mixed header+toolbar block with a simple h2 + underline
perl -0777 -i -pe '
  s{
    <section\b[^>]*id="dashboard"[^>]*>\s*
    <div\s+class="[^"]*?\bmb-3\b[^"]*?">\s*
      <h2[^>]*>\s*Job\s+Dashboard\s*<\/h2>\s*
      <div[^>]*>.*?<\/div>\s*
    <\/div>
  }{
    <section class="bg-white p-4 rounded-xl shadow" id="dashboard" style="margin-top:0">\n<h2 class="text-xl font-semibold mb-3 border-b pb-2">Job Dashboard</h2>
  }gsx' "$HDR"

# 2c) Insert one bottom-right toolbar (small buttons) after #dbAlerts; first remove any existing bottom toolbars to avoid duplicates.
perl -0777 -i -pe '
  s/\n\s*<div class="mt-3\s+flex[^"]*>\s*<button[^>]*id="dashSave"[\s\S]*?<\/div>//g;
  s/(<div class="mt-3 text-xs" id="dbAlerts"><\/div>)/\1\n<div class="mt-3 flex gap-2 justify-end no-print">\n  <button class="rw-btn rw-btn--secondary rw-btn--sm" id="dashUndo">Undo<\/button>\n  <button class="rw-btn rw-btn--secondary rw-btn--sm" id="dashQuote">Quote<\/button>\n  <button class="rw-btn rw-btn--positive  rw-btn--sm" id="dashBook">Book<\/button>\n  <button class="rw-btn rw-btn--positive  rw-btn--sm" id="dashSave">Save<\/button>\n<\/div>/;
' "$HDR"

echo "[done] UI consistency fix applied."
git status --porcelain
