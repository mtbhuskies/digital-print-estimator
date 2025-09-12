#!/usr/bin/env bash
set -euo pipefail

FILE="src/App.jsx"
[ -f "$FILE" ] || { echo "❌ $FILE not found"; exit 1; }

# 1) Make LayoutDiagram support `showMetrics` and `compact` (no-op if already done)
#    - Add props if signature doesn't have them yet.
perl -0777 -i -pe '
  s/function\s+LayoutDiagram\s*\(\{\s*line\s*\}\)/function LayoutDiagram({ line, showMetrics = true, compact = false })/s
' "$FILE"

# 2) Remove the mini “24 up · 3×8 · 0°” header (keep the title only)
perl -0777 -i -pe '
  s{
    <div\s+className="flex\s+items-center\s+justify-between">\s*
    <div\s+className="text-\[12px\]\s+font-semibold\s+text-stone-700">Layout Diagram</div>\s*
    <div[^>]*>.*?</div>\s*
    </div>
  }{<div className="text-[12px] font-semibold text-stone-700">Layout Diagram</div>}sx
' "$FILE"

# 3) Make the gray box “compact” on Presets and keep default on Job via prop
#    (We set compact on Presets usage later; here we just ensure the container supports compact.)
perl -0777 -i -pe '
  s{
    (<div\s+className="mt-2\s+)(bg-stone-50\s+border\s+border-stone-200\s+rounded-lg\s+)(p-2)(">)
  }{$1 . ($3 =~ /compact/ ? "p-1" : "p-2") . $2 . $3}sex
' "$FILE" 2>/dev/null || true  # best-effort; harmless if it doesn’t match

# 4) JOB PAGE — change Layout block grid to: [fields 1fr | diagram auto]
#    Replace the outer grid classes and child wrappers.
perl -0777 -i -pe '
  s{
    (<Section\s+title="Layout">.*?)
    <div\s+className="grid\s+grid-cols-1\s+md:grid-cols-5\s+md:gap-4\s+gap-2">\s*
    \s*<div\s+className="md:col-span-3\s+space-y-3">\s*
  }{
    $1
    <div className="grid grid-cols-1 md:grid-cols-[minmax(0,1fr)_auto] md:gap-6 gap-2 items-start">
    <div className="space-y-3">
  }sx;

  s{
    (\{/\*\s*Right:[^*]*\*/\}\s*)
    <div\s+className="md:col-span-2">\s*
    <LayoutDiagram
  }{
    $1
    <div className="justify-self-start">
    <LayoutDiagram compact={true}
  }sx;
' "$FILE"

# 5) PRESETS PAGE — editor row to: [details 1fr | diagram auto], compact & no metrics
perl -0777 -i -pe '
  s{
    (<div\s+className="grid\s+grid-cols-1\s*)sm:grid-cols-5(\s*gap-4\s*">)
  }{$1sm:grid-cols-[minmax(0,1fr)_auto] gap-6 items-start">}sx;

  s{
    (\{\s*previewLine\s*&&\s*<LayoutDiagram\s+line=\{previewLine\})
    (\s*(?:[^>]|>(?<!\/>))*?)
    (\s*\/>)
  }{$1 showMetrics={false} compact={true} /> }sx;

  s{
    (<div\s+className=")sm:col-span-2(">\s*\{\s*previewLine\s*&&\s*<LayoutDiagram)
  }{<div className="justify-self-start">$2}sx;
' "$FILE"

echo "✅ Applied layout tweaks to $FILE"