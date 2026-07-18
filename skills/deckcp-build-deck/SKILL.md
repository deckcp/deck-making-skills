---
name: deckcp-build-deck
description: Build a real DeckCP deck from a brief or outline — generate the outline, generate on-brand slides, validate each one, and render for review. Use when the user says "build the deck", "make the slides", "turn this into a DeckCP deck", or after deck-interview/deck-outline. Requires the DeckCP MCP connected.
argument-hint: "[--brief ./deck-brief/brief.json] [--outline ./deck-brief/outline.json] [--brand <slug>] [--deck <slug>]"
---

# Build Deck (DeckCP MCP orchestration — minimal tokens)

Drive the DeckCP generate pipeline end to end: brief/outline → outline → slides →
check → render. This skill is **orchestration**, not authoring — the MCP's AI
pipeline writes the slides on-brand; your job is to feed it the right context, then
validate and report.

## Why this is mostly not a model step

The heavy generation runs server-side inside DeckCP (`generate_outline`,
`generate_slides_from_outline`). `check_slide` is a **deterministic validator** (no
render, free). Model judgment is only needed to (a) turn a brief/outline into the
`context` string, and (b) decide fixes when `check_slide` flags a slide. Keep token
use low — don't re-narrate slide content the pipeline already produced.

## Step 0 — identity & brand

```
whoami                     # confirm which DeckCP user you are
list_decks                 # orient; is there already a deck to build into?
```

Pick the brand: if the user has one brand, use it; otherwise ask. Fetch it so the
outline respects the design lockdown:

```
get_brand { slug: <brandSlug> }
```

If the token can't see the intended deck later, it's an access issue, not a retry —
tell the user to share the deck with the `whoami` email (see MCP instructions).

## Step 1 — assemble context from the brief/outline

Read whatever exists:

```bash
cat ./deck-brief/brief.json 2>/dev/null; cat ./deck-brief/outline.json 2>/dev/null
```

- **If `outline.json` exists** (preferred): you already have a slide-by-slide spine.
  You can feed it two ways — see Step 3, path A.
- **If only `brief.json` exists**: compose a tight `context` string from it —
  audience, ask, problem, insight, solution, proof, differentiation, objections.
  This is the one place your words matter; make the context a clean brief, not a
  data dump.
- **If neither exists**: run `deck-interview` (and ideally `deck-outline`) first, or
  interview inline. Do not build blind.

## Step 2 — create or reuse the deck

If building into a new deck:

```
create_deck { title, brand_slug, target_audience, description }
```

It returns the `deck_slug`. If reusing, use the existing slug.

## Step 3 — generate

**Path A — you have an outline (preferred).** Generate slides directly from it. You
can pass the outline inline (map `outline.json` slides to the pipeline's outline
array shape) or, to let the pipeline shape it, first:

```
generate_outline { context, brandSlug, slideCount }   # returns outlineId + outline
generate_slides_from_outline { deck_slug, outlineId }  # or { deck_slug, outline }
```

**Path B — brief only.** Let the pipeline outline first:

```
generate_outline { context, brandSlug }                # auto best-fit slideCount
```

Show the returned outline to the user, let them tweak, THEN:

```
generate_slides_from_outline { deck_slug, outlineId }
```

Prefer generating from an outline the user has seen — it's cheaper to fix the story
before slides than after.

## Step 4 — validate every slide (free, deterministic)

Get the deck and run `check_slide` on each slide's MDX:

```
get_deck { slug: deck_slug }          # read back the generated slides + orders
check_slide { mdx_content, frontmatter }   # per slide
```

`check_slide` returns `{ valid, validation_errors, structure_errors, advisories,
balance }`. For any slide with `valid:false` or serious `balance.issues`:

- Fix the MDX yourself and `upsert_slides` the corrected slide at the same
  `slide_order`, OR use `rewrite_slide` if the copy itself needs to change.
- **Authoring rule (important):** `upsert_slides` strips inline styles and preset
  styles. Use the `deck-*` vocabulary classes only — never inline `style=` or
  arbitrary `text-[Npx]`. If unsure, call `get_authoring_guide topic='contract'`
  for the class vocabulary and `topic='components'` for the component catalog.
- Re-run `check_slide` after each fix until `valid:true`.

Use `slide_order` gaps of 10 (10, 20, 30…) so slides can be inserted later.

## Step 5 — render for review

```
render_slides { deck_slug }     # no format → opens the user-visible inline viewer
```

For your own inspection while fixing a specific slide, use
`render_slides { deck_slug, slide_orders:[N], format:'image' }` (the user can't see
those — they're for your eyes). Present the deck to the user with the plain
`render_slides { deck_slug }` call.

## Step 6 — hand off

Summarize what you built (slide count, the spine, anything `check_slide` flagged and
how you fixed it). Then point onward:

> "Run `deck-critique` to pressure-test the narrative, `deckcp-gather-assets` to
> swap in your real photos, or `deckcp-share` to send it out."

## Guardrails

- Never fabricate proof or numbers to fill a slide. If the brief has none, the slide
  says so or is cut — flag it to the user.
- Fix the story before the slides. A clean render of a weak outline is still a weak
  deck.
- Keep tokens low: don't paste full slide MDX back to the user; report by headline.
