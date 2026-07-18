---
name: deckcp-gather-assets
description: Collect a user's own images/videos from their machine into one folder and upload them to DeckCP for use in slides. Use when the user says "gather my assets", "find my photos", "use my own images", or before building a deck that should use their real photos/screenshots/logos.
argument-hint: "[--out ./deck-assets] [--min-kb 40] [--roots \"~/Pictures:~/Desktop\"]"
---

# Gather Assets (script-first, zero tokens for the search)

Pull the user's real images/videos into one folder, dedupe them, and upload the
keepers to DeckCP so slides can reference their own photos instead of generated
or stock art.

## Why this is script-first

Finding, hashing, and copying files is a solved problem for the shell — doing it
with model tokens would be slow, expensive, and non-deterministic. The **only**
place judgment belongs is *choosing which collected assets to actually upload*,
and even that is optional. So:

```
find + stat + shasum + cp   ← scripts/find-assets.sh (deterministic, free)
        │
        ▼
  ./deck-assets/*.jpg + assets.csv
        │  (optional) Haiku subagent picks the on-brand keepers
        ▼
  DeckCP MCP: upload_asset (base64)  → search_assets can now find them
```

## Step 1 — collect (no tokens)

Run the finder. It searches the roots, skips files under `--min-kb`, de-dupes by
SHA-256 content hash, copies survivors into `--out`, and writes `assets.csv`
(`hash,bytes,ext,source_path,copied_as`). Stock macOS bash 3.2 compatible.

```bash
bash scripts/find-assets.sh --out ./deck-assets --min-kb 40 \
  --roots "$HOME/Pictures:$HOME/Desktop:$HOME/Downloads:$HOME/Documents"
```

Report the summary line (collected / skipped-small / duplicates) back to the user
and ask if they want to add other roots (external drives, a project folder, etc.)
before uploading.

### macOS Photos library

Photos aren't loose files — they live inside `~/Pictures/Photos Library.photoslibrary`.
Don't crawl that package directly (originals are opaque + duplicated). Instead ask
the user to **drag the photos they want into a folder** (or File ▸ Export), then
point `--roots` at that folder. If they'd rather not, that's fine — skip Photos.

## Step 2 — (optional) curate

If there are many assets and only some fit the deck, spawn a **Haiku** subagent
(Agent tool, `model: "haiku"`) over `assets.csv` to shortlist by filename/intent,
or just show the user the folder and let them delete rejects. Keep it optional —
uploading everything is fine for small sets.

## Step 3 — upload to DeckCP

For each keeper, call the DeckCP MCP `upload_asset` tool with base64 `data` and
the right `content_type`. Images only for base64 (cap 8MB); **videos** must be
hosted first and passed via `source_url`. After upload, `search_assets` and the
returned public URL are usable as `backgroundImage`, inline `<img>`, or
`<video src>` in slide MDX.

Batch politely: upload in small groups, surface each returned URL, and record
them (append the URL as a column to `assets.csv`) so a later build step can
reference assets by hash without re-uploading.

## Guardrails

- **Only the user's own machine.** This skill copies local files the user points
  at; it never reaches outside the given roots.
- **Copies, never moves** — originals are untouched.
- Large libraries: warn before crawling `$HOME` wholesale; prefer specific roots.
