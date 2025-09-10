# fix-job-dashboard-toolbar.sh
#!/usr/bin/env bash
set -euo pipefail

HDR="src/partials/header.html"
DIST="dist/printing_estimator.build.html"

# Canonical toolbar block (keep exactly one)
read -r -d '' TOOLBAR <<'HTML'
<div class="mt-3 flex gap-2 justify-end no-print">
  <button class="rw-btn rw-btn--secondary rw-btn--sm" id="dashUndo">Undo</button>
  <button class="rw-btn rw-btn--secondary rw-btn--sm" id="dashQuote">Quote</button>
  <button class="rw-btn rw-btn--positive  rw-btn--sm" id="dashBook">Book</button>
  <button class="rw-btn rw-btn--positive  rw-btn--sm" id="dashSave">Save</button>
</div>
HTML

# 1) Remove ANY existing toolbar blocks that contain dash* ids (defensive dedupe).
/usr/bin/perl -0777 -i -pe '
  s|\n\s*<div[^>]*>\s*(?:(?!</div>).)*(?:id="dashUndo"|id="dashQuote"|id="dashBook"|id="dashSave").*?</div>\s*||gs
' "$HDR" 2>/dev/null || true
/usr/bin/perl -0777 -i -pe '
  s|\n\s*<div[^>]*>\s*(?:(?!</div>).)*(?:id="dashUndo"|id="dashQuote"|id="dashBook"|id="dashSave").*?</div>\s*||gs
' "$DIST" 2>/dev/null || true

# 2) Insert ONE canonical toolbar after the alerts div if not already present.
/usr/bin/perl -0777 -i -pe '
  my $tb = $ENV{TB};
  s|( <div\s+class="mt-3\s+text-xs"\s+id="dbAlerts"></div> )(?!.*?id="dashSave")|$1\n$tb\n|s
' "$HDR"
TB="$TOOLBAR" /usr/bin/perl -0777 -i -pe '
  my $tb = $ENV{TB};
  s|( <div\s+class="mt-3\s+text-xs"\s+id="dbAlerts"></div> )(?!.*?id="dashSave")|$1\n$tb\n|s
' "$DIST"

# 3) Sanity: ensure exactly one Save button remains in each file.
for f in "$HDR" "$DIST"; do
  [ -f "$f" ] || continue
  n=$(/usr/bin/grep -c 'id="dashSave"' "$f" || true)
  echo "$f -> dashSave count: $n"
done

echo "Done. One toolbar remains in header.html and the built file."
