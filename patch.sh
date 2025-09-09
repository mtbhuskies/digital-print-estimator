#!/usr/bin/env bash
set -euo pipefail

CSS="src/css/style.css"

# 1) Replace the old aspect-ratio hack on .canvas-container with a real height.
#    Height scales with viewport but is capped to avoid absurdly tall panels.
perl -0777 -i -pe '
  s/\.canvas-container\s*\{[^}]*\}/.canvas-container{ width:100%; height:clamp(300px,60vh,700px); position:relative; background:#f3f4f6; border-radius:12px; }/s
' "$CSS"

# 2) Scope the canvas rule to just the imposition canvas, and ensure it fills the container.
#    (Leaves any other <canvas> elements alone.)
perl -0777 -i -pe '
  s/\bcanvas\s*\{[^}]*\}/#impositionCanvas{ position:absolute; inset:0; width:100%; height:100%; border:1px solid #e2e8f0; border-radius:12px; pointer-events:none; }/s
' "$CSS"

echo "[ok] Layout Diagram sizing fixed in $CSS"
git status --porcelain
