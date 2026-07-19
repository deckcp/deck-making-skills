# DeckCP MCP — complete tool reference

Every tool the [DeckCP](https://deckcp.com) MCP server exposes — 34 in all —
grouped by what they're for, with access requirements and the skill in this
pack that teaches the workflow around each. Connect the MCP, then any tool
below is callable from your agent.

## How access works

- Your bearer token maps to **one DeckCP user** (`whoami` tells you which).
  All tools run as that user.
- **Read** a deck (render, get): owner, org member, or any share grant.
- **Write** slides (upsert, rewrite, delete, generate): owner, org member,
  or an `editor`/`owner` grant.
- **Sharing tools** are owner-level only (owner, org member, or an `owner`
  grant) — an editor can change slides but not who sees them.
- **Analytics & CRM** are owner/org surfaces — a share grant or public link
  is never enough to see who viewed.
- A per-deck "not authorized" error is not a token problem; share the deck
  with the `whoami` email. A 401 is a token problem; reconnect.

## Identity & orientation

| Tool | What it does |
| --- | --- |
| `whoami` | The authenticated user's id + email. Run first; sharing errors resolve to "share the deck with this email". |
| `list_decks` | All non-deleted decks — slug, title, description, audience, slide count. `search` filters by title; `include_archived` optional. |
| `get_deck` | One deck by slug: metadata + ordered slides (id, order, frontmatter, MDX). On MCP-Apps hosts it also opens the inline deck viewer. |
| `install_deck_skills` | Returns the install procedure for this skill pack (repo, raw URLs, a ready-to-run Node script). No auth or deck access needed. |

Skill: [`deckcp-read-deck`](skills/deckcp-read-deck/SKILL.md).

## Deck lifecycle

| Tool | What it does |
| --- | --- |
| `create_deck` | New deck (placeholder first slide). Requires `title` + `brand_slug`; slug auto-derived if omitted. |
| `update_deck` | Metadata + theme: title, description, audience, brand move, archive. `deck_theme` is **shallow-merged** — change `accent` alone; `null` clears a field back to brand default. Fields: `accent`, `secondary`, `fontDisplay`, `fontBody`, `defaultMood`, `pageMargin`. |
| `delete_deck` | ⚠️ Soft-deletes the deck **and all its slides**. Reversible only via the database. Confirm with the user, always. |

Skills: [`deckcp-build-deck`](skills/deckcp-build-deck/SKILL.md) (create),
[`deckcp-edit`](skills/deckcp-edit/SKILL.md) (update).

## Slides — write, validate, view

| Tool | What it does |
| --- | --- |
| `upsert_slides` | Create/replace slides keyed by `(deck_slug, slide_order)`; a version snapshot is saved before overwrite. Each slide takes **either** `mdx_content` or `slide_tree` (editor-native, full fidelity). Strips inline styles from MDX — `deck-*` vocabulary classes only. Use order gaps of 10. |
| `rewrite_slide` | AI copilot rewrites ONE slide from a natural-language instruction; it sees the current slide, contract, and brand lockdown, persists the result, and returns a fresh `check_slide` report. |
| `delete_slides` | Soft-delete slides by id (ids from `get_deck`). |
| `reorder_slides` | Pass the **complete** id list in the new order; renumbers to 10/20/30; atomic. |
| `duplicate_slide` | Exact copy of one slide, placed after the original (or at a given order). |
| `check_slide` | Free, deterministic, no render: class-vocabulary validation, structure lint, layout-balance analysis on the 1920×1080 canvas, catalog-tag advisories. Run before every upsert and after every edit. |
| `render_slides` | Intent first: bare `{deck_slug}` shows the user the inline viewer; `format:'image'` returns bitmaps **only you** can see (for inspecting your own edits); `format:'urls'`/`'html'` return links/snapshots. Rendering is incremental; `refresh:true` after theme/master changes. |

Skills: [`deckcp-edit`](skills/deckcp-edit/SKILL.md),
[`deckcp-build-deck`](skills/deckcp-build-deck/SKILL.md).

## Generation (server-side AI pipelines)

| Tool | What it does |
| --- | --- |
| `generate_outline` | Context text → outline array + saved `outlineId`. Does not create slides. Pass `brandSlug` so the outline respects the brand lockdown. |
| `generate_slides_from_outline` | Approved outline (`outlineId` or inline array) → finalized on-brand slides written to the deck. |
| `generate_slides_from_text` | One-shot: raw context → slides appended to a deck, optional reference image. Faster but skips the outline-review step — prefer the outline path so the user sees the story before slides exist. |

Skill: [`deckcp-build-deck`](skills/deckcp-build-deck/SKILL.md).

## Authoring reference (read-only, no side effects)

| Tool | What it does |
| --- | --- |
| `get_authoring_guide` | The ground truth for writing slides. `topic:'contract'` → MDX rules + class vocabulary + canvas budget; `'components'` → props/examples for ~60+ components and charts (Card, Stat, LineChart, FlowDiagram, Timeline…); `'classes'` → the machine-readable `allowed_classes` array. |
| `get_brand` | Brand record + rendered design lockdown: palette, logos, approved images, guidelines, non-negotiable rules. Fetch before generating or authoring. |
| `list_style_presets` | Named presets usable via `data-preset` on nodes and in masters' title/subtitle zones — built-ins plus the deck's custom presets. |
| `get_masters` | A deck's master slides (named layouts: background, logo slot, title/subtitle presets, footers, decor layer), MERGED across global ← brand ← deck scopes. Assign via `frontmatter.master` in `upsert_slides`. |
| `set_masters` | Replace the master array wholesale (get, modify, PUT back). `scope:'deck'` needs editor access; `scope:'brand'` (owner/org) installs a house style inherited by **every** deck on the brand. Follow with `render_slides refresh:true`. |

Skill: [`deckcp-author-slides`](skills/deckcp-author-slides/SKILL.md) — the
manual-editing skill built on this whole group (contract, presets, masters).

## Assets

| Tool | What it does |
| --- | --- |
| `upload_asset` | Image/video → deck-assets bucket → public URL for slides. Base64 `data` (images, ≤8MB) or `source_url` (required for videos, ≤50MB). |
| `search_assets` | Semantic search over the shared asset library (url, description, tags, similarity) — reuse approved images instead of generating. |

Skill: [`deckcp-gather-assets`](skills/deckcp-gather-assets/SKILL.md).

## Sharing & access

| Tool | What it does |
| --- | --- |
| `list_deck_access` | Every per-person grant + role, the deck-wide `share_mode`, password-set flag, `allow_remix`. Call before any change. |
| `share_deck` | Invite emails with a role (`viewer`/`commenter`/`editor`/`owner`); re-sharing updates the role without re-emailing, so it's also the role-change tool. `notify:false` skips invite mail. |
| `revoke_deck_access` | Remove per-person grants. Does NOT close a public link — check the gate too. |
| `set_deck_share_mode` | The deck-wide gate: `private` / `public` / `email` (viewers identify → become leads) / `password`; plus `allow_remix` (viewers can duplicate as a template). |

Skill: [`deckcp-share`](skills/deckcp-share/SKILL.md).

## Analytics & CRM

| Tool | What it does |
| --- | --- |
| `get_deck_analytics` | One deck's audience: sessions, identified vs anonymous, idle-trimmed engaged time, completions, the per-slide dwell curve, recent sessions. |
| `list_leads` | The org's lead board — everyone who was invited to or viewed the org's decks, overlaid with CRM state (stage, assignee, note, score) and the email journey. Filter by stage/search. |
| `get_lead` | One person by email: CRM state, per-deck engagement (visits, dwell per slide, completion), follow-up email ledger with opens, full activity timeline. |
| `update_lead` | Write the CRM overlay: pipeline stage (logged to the timeline), note, assignee, editable contact fields. Only for people with existing activity. |
| `create_contact` | Manually add a contact with no deck activity (business card, a call). Email optional; when given, upserts-by-email. |

Skill: [`deckcp-analyze`](skills/deckcp-analyze/SKILL.md) (paired with
[`deckcp-email`](skills/deckcp-email/SKILL.md) for the follow-up).

## Personal

| Tool | What it does |
| --- | --- |
| `search_voice_memos` | Semantic search over the account's voice-memo transcripts — ranked by meaning, returns date/place/topic + excerpt. Feeds `create_contact` ("the founder I met Tuesday") and deck context. |

No skill yet.

## Coverage map

| Group | Tools | Documented by |
| --- | --- | --- |
| Identity & orientation | 4 | `deckcp-read-deck`, README (install) |
| Deck lifecycle | 3 | `deckcp-build-deck`, `deckcp-edit` — `delete_deck` intentionally has no skill |
| Slides | 7 | `deckcp-edit`, `deckcp-build-deck` |
| Generation | 3 | `deckcp-build-deck` — `generate_slides_from_text` mentioned here only |
| Authoring reference | 5 | `deckcp-author-slides` (manual editing: contract, presets, masters) |
| Assets | 2 | `deckcp-gather-assets` — `search_assets` mentioned here only |
| Sharing | 4 | `deckcp-share` |
| Analytics & CRM | 5 | `deckcp-analyze` |
| Personal | 1 | none |

---

Generated from the MCP server's own tool schemas. If a tool call disagrees
with this page, the server is right — file an issue.
