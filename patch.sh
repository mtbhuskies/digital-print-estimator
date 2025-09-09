#!/usr/bin/env bash
set -euo pipefail

CSS="src/css/style.css"
HDR="src/partials/header.html"

# 1) Page background: light neutral so cards stand out
#    (idempotent: only appends once)
if ! grep -q "/* App background */" "$CSS"; then
  cat >>"$CSS" <<'CSS'

/* App background */
body{ background:#f8fafc; } /* Tailwind slate-50 */
CSS
  echo "[ok] App background appended to $CSS"
else
  echo "[skip] App background already present in $CSS"
fi

# 2) Compact button size modifier .rw-btn--sm (idempotent)
if ! grep -q '\.rw-btn--sm' "$CSS"; then
  cat >>"$CSS" <<'CSS'

/* Compact buttons (tight headers like Job Dashboard) */
.rw-btn--sm{
  --rw-btn-h: 34px;
  --rw-btn-px: 12px;
  --rw-btn-fs: 0.8125rem; /* ~13px */
  --rw-btn-radius: 8px;
}
.rw-btn--sm .rw-icon{ width:16px; height:16px; }
CSS
  echo "[ok] .rw-btn--sm appended to $CSS"
else
  echo "[skip] .rw-btn--sm already present"
fi

# Helper: overwrite class attribute on a <button> by id (safe & deterministic)
rb_id() {
  local f="$1" id="$2" klass="$3"
  # id before class
  perl -0777 -i -pe "s/(<button\\b[^>]*\\bid=\"$id\"[^>]*\\bclass=\")[^\"]*(\"[^>]*>)/\\1$klass\\2/g" "$f"
  # class before id
  perl -0777 -i -pe "s/(<button\\b[^>]*\\bclass=\")[^\"]*(\"[^>]*\\bid=\"$id\"[^>]*>)/\\1$klass\\2/g" "$f"
}

echo "[info] Compacting Job Dashboard buttons…"

# 3) Apply compact sizing to the four dashboard buttons
# (colors stay as you already mapped in header.html)
rb_id "$HDR" "dashSave"  "rw-btn rw-btn--secondary rw-btn--sm"
rb_id "$HDR" "dashBook"  "rw-btn rw-btn--positive  rw-btn--sm"
rb_id "$HDR" "dashUndo"  "rw-btn rw-btn--danger    rw-btn--sm"
rb_id "$HDR" "dashQuote" "rw-btn rw-btn--secondary rw-btn--sm"

echo "[done] Background set; dashboard buttons compacted."
git status --porcelain
