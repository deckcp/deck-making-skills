#!/usr/bin/env bash
# scaffold-outline.sh — write empty outline.json + outline.md. Zero tokens.
# Stock macOS bash 3.2 compatible. No $() (Bash tool blocks it).
set -eu

OUT="./deck-brief"
while [ $# -gt 0 ]; do
  case "$1" in
    --out) OUT="$2"; shift 2 ;;
    *) echo "unknown arg: $1" >&2; exit 2 ;;
  esac
done

mkdir -p "$OUT"
OJSON="$OUT/outline.json"
OMD="$OUT/outline.md"

if [ -f "$OJSON" ]; then
  echo "outline.json already exists at $OJSON — leaving it in place."
else
  cat > "$OJSON" <<'JSON'
{
  "deck_type": "",
  "audience": "",
  "ask": "",
  "spine": "",
  "slides": [],
  "cut": []
}
JSON
  echo "Wrote template: $OJSON"
fi

if [ -f "$OMD" ]; then
  echo "outline.md already exists at $OMD — leaving it in place."
else
  cat > "$OMD" <<'MD'
# Deck outline

_One line per slide: the headline states the conclusion, not the topic._

1.
2.
3.
MD
  echo "Wrote template: $OMD"
fi
