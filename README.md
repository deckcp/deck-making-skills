# DeckCP deck-making skills

A [Claude Code](https://claude.com/claude-code) skill pack for making decks that
actually work — built for **founders, salespeople, and BD** who need a deck to
*make something happen*, not just look finished.

Most AI deck tools skip straight to slides. This pack doesn't. It interrogates
you first, fixes the story, and only then builds — because a deck fails at the
narrative level long before it fails at the design level.

## Start here

1. **Install the pack** (two ways, below — takes a minute).
2. **Connect the DeckCP MCP** — mint a token or use the OAuth connector at
   [deckcp.com/mcp](https://deckcp.com/mcp). *Optional to start:* the Tier 1
   skills (interview, outline, GitHub lookup) work with no account at all.
3. **Run `/deckcp-onboard`** — it checks your setup, orients on your decks and
   brand, asks one question about what you're trying to make happen, and routes
   you to the right skill. New user? It'll walk you into building your first
   real deck end to end.

## The workflow

```
/deck-interview → /deck-outline → /deckcp-build-deck → /deckcp-share → /deckcp-analyze
   brief.json       outline.json     a real DeckCP deck     out the door     who viewed, who to
                                                                             follow up with
```

1. **`/deck-interview`** — gets grilled *by* your agent: who is this deck for,
   what must it make happen, what's the ask, where's the proof. It pushes back
   on weak positioning instead of politely transcribing it. Emits `brief.json`.
2. **`/deck-outline`** — turns the brief into a story spine, picked for the
   deck type (investor, sales, partnership; live vs. sent-as-link) — so every
   slide earns its place and every headline states a conclusion, not a topic.
3. **`/deckcp-build-deck`** — drives the [DeckCP](https://deckcp.com) pipeline:
   generate on-brand slides, validate each one, render for review.
4. **`/deckcp-share`** — invite people with roles, or set the gate: public
   link, email-gated (views become identified leads), or password.
5. **`/deckcp-analyze`** — read the per-slide dwell curve like an editor: the
   slide where viewers drop off is your next edit. Then `/github-lookup` +
   `/deckcp-email` to work the follow-up.

And in between: `/deckcp-read-deck` to orient on any existing deck, and
`/deckcp-edit` to change it — theme, copy, order — without regenerating.

Steps 1–2 work with **no DeckCP account at all**. Use them with any deck tool.

## Install

**With the DeckCP MCP connected:** ask your agent to call
**`install_deck_skills`** — it fetches these files into your `.claude/skills`.

**Manually** (Node 18+):

```bash
node - <<'JS'
(async () => {
  const fs = require('fs'), path = require('path'), os = require('os');
  const rawBase = 'https://raw.githubusercontent.com/deckcp/deck-making-skills/main';
  const treeApi = 'https://api.github.com/repos/deckcp/deck-making-skills/git/trees/main?recursive=1';
  let dest = '.claude/skills'; // use '~/.claude/skills' to install globally
  if (dest === '~' || dest.startsWith('~/')) dest = path.join(os.homedir(), dest.slice(1));
  const tree = (await (await fetch(treeApi)).json()).tree || [];
  for (const e of tree) {
    if (e.type !== 'blob' || !e.path.startsWith('skills/')) continue;
    const out = path.join(dest, e.path.replace(/^skills\//, ''));
    fs.mkdirSync(path.dirname(out), { recursive: true });
    fs.writeFileSync(out, Buffer.from(await (await fetch(rawBase + '/' + e.path)).arrayBuffer()));
    if (out.endsWith('.sh')) fs.chmodSync(out, 0o755);
    console.log('wrote', out);
  }
})();
JS
```

Restart Claude Code so the new `SKILL.md` files are picked up, then invoke any
skill by name: `/deck-interview`, `/deck-outline`, `/deckcp-build-deck`.

## The skills

Two tiers. **Tier 1** is provider-agnostic deck craft — useful with no DeckCP
account. **Tier 2** drives the DeckCP MCP to build, edit, and share real decks —
the full 34-tool surface is documented in [`MCP-TOOLS.md`](MCP-TOOLS.md).

| Skill | Tier | What it does |
| --- | --- | --- |
| `deckcp-onboard` | 1 | Start here: checks your setup, orients, and routes you to the right skill with one question. |
| `deck-interview` | 1 | Interview you about audience, goal, ask, and proof — and push back on weak positioning. Emits `brief.json`. |
| `deck-outline` | 1 | Build the story spine from the brief before any slides exist. Emits `outline.json` + `outline.md`. |
| `github-lookup` | 1 | Resolve a person from GitHub — username, commit SHA, or email — to a name, profile, and contact. Zero tokens (`gh` CLI). |
| `deckcp-gather-assets` | 2 | Find your own images/videos on disk, dedupe by hash, upload to DeckCP — so slides use your real photos, not stock art. |
| `deckcp-build-deck` | 2 | Brief/outline → generate → validate every slide → render. Orchestration, minimal tokens. |
| `deckcp-read-deck` | 2 | Orient on an existing deck: structure, rendered slides, and the story its headlines tell. The step before any edit. |
| `deckcp-edit` | 2 | Deterministic edit recipes — theme (colors/fonts/margins), update a slide, reorder, duplicate, delete — validated and rendered after every change. |
| `deckcp-author-slides` | 2 | Manual editing: hand-write slides against the rendering contract — exact words, exact layout, charts, presets, masters — when the pipelines shouldn't decide. |
| `deckcp-share` | 2 | Per-person grants with roles + the deck-wide gate (public / email-gated / password / remix). Asks before widening access. |
| `deckcp-analyze` | 2 | Sessions, engaged time, per-slide dwell and drop-off — turned into "fix this slide, follow up with these two people". |
| `deckcp-email` | 2 | Email a contact or lead via the Zavu API — cc, reply-to, dry-run preview by default. Needs `ZAVU_API_KEY`. |

### Roadmap

Planned next (see [`manifest.json`](manifest.json) for the full inventory and status):

- **Critique & analysis** — `deck-critique` (what's weak and why),
  `deck-analyze-consistency` (script-first font/color/terminology scan),
  `deck-analyze-visual` (render each slide and *look* at it),
  `deck-analyze-multi` (investor / sales / skeptic / 5-second-test lenses).
- **Voice** — `deck-writing-samples` distills your tone from things you've written.
- **Brand** — `deckcp-brand` assembles a brand brief (palette, voice, logos).

## Design principles

- **Scripts over tokens.** Deterministic bash/node does the heavy lifting for
  free — asset dedup, hashing, consistency scans, GitHub lookups, sending mail.
- **Right model for the step.** Pure script where possible; a cheap model only
  for mechanical classification; **your own model, not a downgraded one**, for
  the judgment steps — interview, outline, critique — because that's where deck
  quality actually comes from.
- **Useful before you sign up.** Tier 1 stands on its own. If it makes your
  story better, Tier 2 is waiting.

## Requirements

- [Claude Code](https://claude.com/claude-code) (skills runtime)
- Node 18+ for the script-backed skills
- Tier 2 only: the [DeckCP](https://deckcp.com) MCP connected
- `github-lookup`: an authenticated [`gh`](https://cli.github.com) CLI
- `deckcp-email`: `ZAVU_API_KEY` in the environment or `.env.local`

---

Made for [DeckCP](https://deckcp.com) — say the idea, get the slides.
