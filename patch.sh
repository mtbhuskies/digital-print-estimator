#!/usr/bin/env bash
set -euo pipefail

HDR="src/partials/header.html"

# safety backup
cp -n "$HDR" "${HDR}.bak" 2>/dev/null || true

# Canonical toolbar (use --primary for blue)
read -r -d '' TB <<'HTML'
<div class="mt-3 flex gap-2 justify-end no-print" id="dashToolbar">
  <button class="rw-btn rw-btn--secondary rw-btn--sm" id="dashUndo">Undo</button>
  <button class="rw-btn rw-btn--secondary rw-btn--sm" id="dashQuote">Quote</button>
  <button class="rw-btn rw-btn--primary  rw-btn--sm" id="dashBook">Book</button>
  <button class="rw-btn rw-btn--primary  rw-btn--sm" id="dashSave">Save</button>
</div>
HTML

# 1) Remove ANY existing dashboard toolbars (defensive dedupe)
#    Anything with any of the 4 ids or the dashToolbar container.
usrperl=/usr/bin/perl
"$usrperl" -0777 -i -pe '
  s{
    \n\s*<div[^>]*\b(?:id="dashToolbar"|class="[^"]*\bflex\b[^"]*")[^>]*>
    (?:(?!</div>).)*?(?:id="dashUndo"|id="dashQuote"|id="dashBook"|id="dashSave")
    (?:(?!</div>).)*?</div>\s*
  }{}gsx;
' "$HDR"

# 2) Try to insert after the alerts block if present
TB="$TB" "$usrperl" -0777 -i -pe '
  my $tb = $ENV{TB};
  s{(<div\s+class="[^"]*\bmt-3\b[^"]*\btext-xs\b[^"]*"\s+id="dbAlerts"></div>)}{$1\n$tb\n}s;
' "$HDR"

# 3) If still no toolbar (no dbAlerts anchor), insert before </section> of #dashboard
if ! grep -q 'id="dashToolbar"' "$HDR"; then
  TB="$TB" "$usrperl" -0777 -i -pe '
    my $tb = $ENV{TB};
    s{
      (<section[^>]*\bid="dashboard"[^>]*>)
      (.*?)
      (</section>)
    }{
      my ($open,$body,$close)=($1,$2,$3);
      $body =~ /id="dashToolbar"/ ? "$open$body$close" : "$open$body\n$tb\n$close";
    }gse
  ' "$HDR"
fi

# 4) Final sanity: show counts
echo -n "dashToolbar count: "; grep -c 'id="dashToolbar"' "$HDR" || true
echo -n "dashSave     count: "; grep -c 'id="dashSave"' "$HDR" || true

echo "[OK] Exactly one dashboard toolbar ensured in $HDR"
