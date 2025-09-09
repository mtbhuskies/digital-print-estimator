#!/usr/bin/env bash
set -euo pipefail

CSS="src/css/style.css"

# 1) Add blue tokens to :root if missing
perl -0777 -i -pe '
  if (!/--rw-info:/) {
    s/(:root\{.*?)(\n\})/$1\n  --rw-info: #2563eb;\n  --rw-info-hover: #1d4ed8;$2/s;
  }
' "$CSS"

# 2) Replace .rw-btn--secondary rules (white -> blue)
perl -0777 -i -pe '
  s/\.rw-btn--secondary\s*\{[^}]*\}/.rw-btn--secondary{\n  background: var(--rw-info); color: var(--rw-on-dark);\n}/s;
  s/\.rw-btn--secondary:hover[^{]*\{[^}]*\}/.rw-btn--secondary:hover:not(:disabled){ background: var(--rw-info-hover); }/s;
' "$CSS"

echo "[ok] Secondary buttons are now blue."
git status --porcelain
