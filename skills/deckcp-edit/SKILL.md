---
name: deckcp-edit
description: Edit an existing DeckCP deck — update a slide's content, change the theme (colors/fonts/margins), reorder, duplicate, or delete slides — using deterministic recipes with validation. Use when the user says "update slide N", "change the accent color", "make the font bigger", "move slide 3 to the end", "delete the pricing slide", or any change to a deck that already exists. Requires the DeckCP MCP connected.
argument-hint: "[--deck <slug>] [--slide <order>]"
---

# Edit a Deck (deterministic recipes — the right tool per change)

Most deck edits are mechanical. This skill maps each kind of change to the
cheapest correct tool, so you never regenerate a deck to fix a font size.

## Why mixed model tiers

Theme, reorder, duplicate, delete are **pure tool calls** — zero judgment.
Mechanical MDX edits are yours (main-loop, but small). Only when the *copy
itself* must be rewritten do you delegate to the server-side slide copilot
(`rewrite_slide`), which sees the brand lockdown you don't.

## Step 0 — read before you write

Run `deckcp-read-deck` (or at minimum `get_deck`) first. You need the slide
ids, orders, and current frontmatter. Never edit blind.

## The recipes

### Change deck-wide look — colors, fonts, margins

`update_deck.deck_theme` shallow-merges, so change one field without wiping
the rest; set a field to `null` to clear it back to brand default:

```
update_deck { deck_slug, deck_theme: { accent: "#C8FF00" } }
update_deck { deck_slug, deck_theme: { fontDisplay: "Space Grotesk, sans-serif" } }
update_deck { deck_slug, deck_theme: { pageMargin: 96 } }
update_deck { deck_slug, deck_theme: { accent: null } }        # back to brand
```

Theme fields: `accent`, `secondary`, `fontDisplay`, `fontBody`,
`defaultMood`, `pageMargin`. Also via `update_deck`: `title`, `description`,
`target_audience`, `brand_slug`, `archived`.

### Update one slide's content

Two paths — pick by whether the *words* change:

- **Mechanical edit** (swap an image, fix a typo, change a class, resize a
  chart): take the slide's MDX from `get_deck`, edit it yourself, and write
  it back at the **same slide_order**:

  ```
  upsert_slides { deck_slug, slides: [{ slide_order: N, frontmatter, mdx_content }] }
  ```

  A version snapshot is saved first, so this is revertible.

- **Copy rewrite** (rephrase, shorten, change the argument): delegate to the
  slide copilot — it sees the current slide, the rendering contract, and the
  brand lockdown, and returns a fresh `check_slide` report:

  ```
  rewrite_slide { deck_slug, slide_order: N, instruction: "..." }
  ```

**Authoring rule (non-negotiable):** `upsert_slides` strips inline styles
and preset styles from MDX. Use `deck-*` vocabulary classes only — never
`style=` or arbitrary `text-[Npx]`. Unsure? `get_authoring_guide
topic='contract'` for classes, `topic='components'` for the catalog.

### Reorder

`reorder_slides` takes the **complete** list of slide ids in the new order
(it renumbers to 10, 20, 30…; atomic, rolls back on a bad list):

```
reorder_slides { deck_slug, slide_ids: [<ALL ids, new order>] }
```

To move one slide: pass all ids with that one repositioned.

### Duplicate / delete

```
duplicate_slide { deck_slug, slide_id }            # copy lands right after the original
delete_slides { slide_ids: [...] }                 # soft-delete (deleted_at)
```

### Insert a new slide

Pick an unused order between neighbors (the gaps-of-10 convention exists for
this: between 20 and 30, use 25) and `upsert_slides` it.

## Always: validate, then look

After any content change:

```
check_slide { mdx_content, frontmatter }                       # free, deterministic
render_slides { deck_slug, slide_orders:[N], format:'image' }  # inspect your work
render_slides { deck_slug }                                    # show the user
```

Fix until `valid:true`. Never report an edit done without having rendered it.

## Guardrails

- Confirm before `delete_slides` — name the slides you're about to remove.
- One change per write: don't bundle a theme change and a content rewrite
  into one opaque step; the user should see each land.
- Don't regenerate (`generate_slides_*`) to fix an edit-sized problem.
