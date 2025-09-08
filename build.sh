#!/usr/bin/env bash
set -euo pipefail

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SRC="$here/src"
OUT_DIR="$here/dist"
TPL="$SRC/index.template.html"
OUT="$OUT_DIR/printing_estimator.build.html"

mkdir -p "$OUT_DIR"

expand_file() {
  local file="$1"
  while IFS= read -r line || [ -n "$line" ]; do
    if [[ "$line" == *"@@include:"* ]]; then
      # extract path after @@include:
      local inc
      inc="$(printf '%s\n' "$line" | sed -E 's/.*@@include:[[:space:]]*([^ >]+).*/\1/')" || inc=""
      if [[ -n "${inc:-}" && -f "$SRC/$inc" ]]; then
        expand_file "$SRC/$inc"
      else
        printf '%s\n' "$line"
      fi
    else
      printf '%s\n' "$line"
    fi
  done < "$file"
}

expand_file "$TPL" > "$OUT"
echo "Built -> $OUT"
