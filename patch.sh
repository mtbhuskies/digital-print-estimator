#!/usr/bin/env bash
set -euo pipefail

CSS="src/css/style.css"
HDR="src/partials/header.html"

# 1) Add unified card header styles (once).
if ! grep -q '/* Card header */' "$CSS"; then
  cat >>"$CSS" <<'CSS'

/* Card header */
:root{
  --rw-card-header-bg:#f1f5f9;   /* slate-100: subtle solid */
  --rw-card-header-fg:#0f172a;   /* slate-900 text */
  --rw-card-header-border:#e2e8f0; /* slate-200 divider */
  --rw-card-radius-xl:0.75rem;   /* matches rounded-xl */
}
/* Use inside white, padded cards (e.g., bg-white p-4 rounded-xl shadow) */
.rw-card__header{
  background:var(--rw-card-header-bg);
  color:var(--rw-card-header-fg);
  border-bottom:1px solid var(--rw-card-header-border);
  /* pull to card edges (cards use p-4 = 1rem) */
  margin:-1rem -1rem 0.75rem;
  padding:.75rem 1rem;
  border-top-left-radius:var(--rw-card-radius-xl);
  border-top-right-radius:var(--rw-card-radius-xl);
}
.rw-card__title{ font-weight:700; font-size:1.125rem; line-height:1.5rem; } /* ~text-lg */
CSS
  echo "[ok] Added unified card header styles to $CSS"
else
  echo "[skip] Card header styles already present"
fi

# 2) Layout Diagram: replace the inline <h2> with a unified header block.
perl -0777 -i -pe '
  s{
    <h2\s+class="[^"]*\bborder-b\b[^"]*">\s*Layout\s+Diagram\s*</h2>
  }{
    <div class="rw-card__header">\n  <h2 class="rw-card__title">Layout Diagram</h2>\n</div>
  }sx' "$HDR"

# 3) Job Dashboard: normalize the header block to the same unified header.
#    Handles both variants (with or without a buttons container).
perl -0777 -i -pe '
  s{
    <div\s+class="[^"]*\bmb-3\b[^"]*">\s*
      <h2[^>]*>\s*Job\s+Dashboard\s*</h2>
      (?:\s*<div[^>]*>.*?</div>)?     # optional button group
    \s*</div>
  }{
    <div class="rw-card__header">\n  <h2 class="rw-card__title">Job Dashboard</h2>\n</div>
  }gsx' "$HDR"

echo "[done] Unified card headers applied."
git status --porcelain
