# DeckCP deck-making skills

A [Claude Code](https://claude.com/claude-code) skill pack for making great decks.
Two tiers:

1. **Provider-agnostic deck craft** — interview, outline, and critique that work
   with **no DeckCP account**. Useful on their own.
2. **DeckCP-powered** — skills that drive the [DeckCP](https://deckcp.com) MCP to
   build, edit, analyze, and share real decks.

## Install

If you have the DeckCP MCP connected, just ask your agent to call
**`install_deck_skills`** — it fetches these files into your `.claude/skills`.

Or install manually with Node 18+ (has global `fetch`):

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

Restart Claude Code so the new `SKILL.md` files are picked up, then invoke them
like `/deck-interview`, `/deck-outline`, `/deckcp-build-deck`.

## Skills

See [`manifest.json`](manifest.json) for the full inventory and status. Highlights:

| Skill | Tier | What it does |
| --- | --- | --- |
| `deck-interview` | 1 | Interrogate a founder/salesperson/BD, push back on weak positioning, emit `brief.json`. |
| `deck-outline` | 1 | Turn the brief into a story spine before any slides. |
| `deckcp-gather-assets` | 2 | Find/dedupe your own images, upload them to DeckCP. |
| `deckcp-build-deck` | 2 | brief/outline → generate → validate → render a real DeckCP deck. |

## Design principles

- **Scripts over tokens** — deterministic bash/node does the heavy lifting for free.
- **Right model for the step** — pure script where possible; a cheap model only for
  mechanical classification; the user's own model for real judgment (interview,
  outline, critique), which is where deck quality actually comes from.

---

Made for [DeckCP](https://deckcp.com) — say the idea, get the slides.
