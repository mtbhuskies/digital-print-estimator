#!/usr/bin/env bash
set -euo pipefail

HDR="src/partials/header.html"
DIST="dist/printing_estimator.build.html"   # optional, if you ship the built file

# Canonical toolbar (small, bottom-right, consistent with your palette)
read -r -d '' TOOLBAR <<'HTML'
<div class="mt-3 flex gap-2 justify-end no-print">
  <button class="rw-btn rw-btn--secondary rw-btn--sm" id="dashUndo">Undo</button>
  <button class="rw-btn rw-btn--secondary rw-btn--sm" id="dashQuote">Quote</button>
  <button class="rw-btn rw-btn--positive  rw-btn--sm" id="dashBook">Book</button>
  <button class="rw-btn rw-btn--positive  rw-btn--sm" id="dashSave">Save</button>
</div>
HTML

fix_file () {
  local f="$1"
  [ -f "$f" ] || return 0
  /usr/bin/perl -0777 -i -pe '
    my $tb = $ENV{TB};

    # operate only within <section id="dashboard">…</section>
    s{
      (<section\b[^>]*\bid="dashboard"[^>]*>)(.*?)(</section>)
    }{
      my ($pre,$body,$post)=($1,$2,$3);

      # 1) remove ANY existing toolbar div that contains a dash* button
      $body =~ s{
        \n\s*<div[^>]*>\s*
          (?:(?!</div>).)*
          (?:id="dashUndo"|id="dashQuote"|id="dashBook"|id="dashSave")
          (?:(?!</div>).)*
        </div>\s*
      }{}gs;

      # 2) if no Save button remains, insert one compact toolbar after #dbAlerts
      if ($body !~ /id="dashSave"/) {
        $body =~ s{
          (<div\b[^>]*\bid="dbAlerts"[^>]*></div>)
        }{$1\n$tb\n}s;
      }
      $pre.$body.$post;
    }egsx;
  ' "$f"
  echo "repaired: $f"
}

export TB="$TOOLBAR"
fix_file "$HDR"
fix_file "$DIST"   # harmless if the file isn’t present

# sanity
for f in "$HDR" "$DIST"; do
  [ -f "$f" ] || continue
  echo -n "check: $f  -> "
  /usr/bin/grep -c 'id="dashSave"' "$f" || true
done

echo "Done. One toolbar in Job Dashboard."
