#!/usr/bin/env bash
# find-assets.sh — deterministic, zero-token asset collection for a DeckCP deck.
#
# Searches one or more roots for images/videos, filters by minimum size,
# de-duplicates by content hash, copies survivors into an output folder, and
# writes assets.csv (hash,bytes,ext,source_path,copied_as). No model calls.
#
# Usage:
#   find-assets.sh [--out DIR] [--min-kb N] [--roots "p1:p2:..."] [--ext "jpg,png,..."]
#
# Defaults: out=./deck-assets, min-kb=40, roots = common macOS media folders.
set -euo pipefail

OUT="./deck-assets"
MIN_KB=40
ROOTS="$HOME/Pictures:$HOME/Desktop:$HOME/Downloads:$HOME/Documents"
EXTS="jpg,jpeg,png,gif,webp,heic,svg,mp4,mov,webm,m4v"

while [ $# -gt 0 ]; do
  case "$1" in
    --out)     OUT="$2"; shift 2 ;;
    --min-kb)  MIN_KB="$2"; shift 2 ;;
    --roots)   ROOTS="$2"; shift 2 ;;
    --ext)     EXTS="$2"; shift 2 ;;
    *) echo "unknown arg: $1" >&2; exit 2 ;;
  esac
done

mkdir -p "$OUT"
CSV="$OUT/assets.csv"
echo "hash,bytes,ext,source_path,copied_as" > "$CSV"

# Build the find name-filter from the extension list (-iname *.jpg -o ...).
IFS=',' read -r -a EXT_ARR <<< "$EXTS"
FIND_EXPR=()
first=1
for e in "${EXT_ARR[@]}"; do
  [ "$first" -eq 0 ] && FIND_EXPR+=( -o )
  FIND_EXPR+=( -iname "*.${e}" )
  first=0
done

MIN_BYTES=$(( MIN_KB * 1024 ))
copied=0
skipped_small=0
skipped_dupe=0
# Portable dedupe (stock macOS bash is 3.2 — no associative arrays): track seen
# content hashes in a temp file, one per line.
SEENFILE="$(mktemp)"
trap 'rm -f "$SEENFILE"' EXIT

# Walk each root. NUL-delimited to survive spaces in paths.
IFS=':' read -r -a ROOT_ARR <<< "$ROOTS"
for root in "${ROOT_ARR[@]}"; do
  [ -d "$root" ] || continue
  while IFS= read -r -d '' f; do
    bytes=$(stat -f%z "$f" 2>/dev/null || echo 0)
    if [ "$bytes" -lt "$MIN_BYTES" ]; then
      skipped_small=$((skipped_small+1)); continue
    fi
    hash=$(shasum -a 256 "$f" | cut -d' ' -f1)
    if grep -qxF "$hash" "$SEENFILE"; then
      skipped_dupe=$((skipped_dupe+1)); continue
    fi
    echo "$hash" >> "$SEENFILE"
    ext="${f##*.}"
    dest="$OUT/${hash:0:12}.${ext}"
    cp -p "$f" "$dest"
    # CSV-quote the source path (may contain commas).
    printf '%s,%s,%s,"%s",%s\n' "$hash" "$bytes" "$ext" "$f" "$(basename "$dest")" >> "$CSV"
    copied=$((copied+1))
  done < <(find "$root" -type f \( "${FIND_EXPR[@]}" \) -print0 2>/dev/null)
done

echo "" >&2
echo "Collected $copied asset(s) into $OUT" >&2
echo "  skipped $skipped_small below ${MIN_KB}KB, $skipped_dupe duplicate(s)" >&2
echo "  manifest: $CSV" >&2
