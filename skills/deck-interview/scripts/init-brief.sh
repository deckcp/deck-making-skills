#!/usr/bin/env bash
# init-brief.sh — scaffold the deck-interview output. Zero tokens.
# Stock macOS bash 3.2 compatible. No $() command substitution (Bash tool blocks it).
set -eu

OUT="./deck-brief"

while [ $# -gt 0 ]; do
  case "$1" in
    --out) OUT="$2"; shift 2 ;;
    --type) shift 2 ;;   # accepted for symmetry; brief.json carries deck_type
    *) echo "unknown arg: $1" >&2; exit 2 ;;
  esac
done

mkdir -p "$OUT"
BRIEF="$OUT/brief.json"

if [ -f "$BRIEF" ]; then
  echo "brief.json already exists at $BRIEF — leaving it in place."
  exit 0
fi

cat > "$BRIEF" <<'JSON'
{
  "deck_type": "",
  "setting": "",
  "audience": { "who": "", "believes": "", "skeptical_of": "" },
  "success_outcome": "",
  "ask": "",
  "problem": "",
  "insight": "",
  "solution_one_sentence": "",
  "proof": [],
  "differentiation": "",
  "unfair_advantage": "",
  "objections": [],
  "assessment": { "strongest": "", "weakest": "", "reframes_applied": [] },
  "voice": ""
}
JSON

echo "Wrote template: $BRIEF"
echo "Fill it in as the interview proceeds."
