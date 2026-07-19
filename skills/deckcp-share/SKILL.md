---
name: deckcp-share
description: Share a DeckCP deck — invite people by email with roles, change or revoke access, and set the deck-wide gate (private / public link / email-gated / password). Use when the user says "share the deck", "send this to <person>", "make it public", "who has access", "revoke <person>", or "let people remix it". Requires the DeckCP MCP connected and owner-level access to the deck.
argument-hint: "[--deck <slug>] [--to <email>...] [--role viewer|commenter|editor|owner]"
---

# Share a Deck (pure tool calls — zero generation)

DeckCP access is two independent layers, Google-Docs style. Know which one
the user means before touching anything:

1. **Per-person grants** — email → role (`viewer`, `commenter`, `editor`,
   `owner`). Managed by `share_deck` / `revoke_deck_access`.
2. **The deck-wide gate** (`share_mode`) — `private` | `public` (anyone with
   the link) | `email` (viewers give an email first) | `password`. Managed by
   `set_deck_share_mode`.

Revoking a grant does NOT close a public link, and going private does NOT
remove grants. "Share with Sam" is layer 1; "make it public" is layer 2;
"send it out to prospects" is usually layer 2 = `email` (so views become
identified leads) plus `deckcp-email` for the outreach itself.

## Step 0 — see current state

Always first:

```
list_deck_access { deck_slug }
```

Returns every grant + role, the current `share_mode`, whether a password is
set, and `allow_remix`. Report this to the user before changing it.

All these tools need **owner-level** access (deck owner, org member, or an
'owner' grant). An editor can change slides but not sharing. If a call is
refused, that's the reason — not a retry.

## Invite / change roles

```
share_deck { deck_slug, emails: ["a@x.com", "b@y.com"], role: "viewer" }
```

- Default role is `viewer`. `notify: false` skips the invite email.
- Re-sharing an existing person **updates their role without re-emailing** —
  so this is also the role-change tool. Bulk change: `list_deck_access`,
  then pass all its emails back with the new role.
- Your own email is silently skipped (`skipped_self`).

## Revoke

```
revoke_deck_access { deck_slug, emails: ["a@x.com"] }
```

Removes per-person grants only. If `share_mode` is `public`, warn the user
the person can still open the link — offer to set the gate to `private` or
`email` too.

## Set the gate

```
set_deck_share_mode { deck_slug, share_mode: "public" }
set_deck_share_mode { deck_slug, share_mode: "email" }        # viewers identify first
set_deck_share_mode { deck_slug, share_mode: "password", password: "..." }
set_deck_share_mode { deck_slug, allow_remix: true }          # gate untouched
```

- `password` is required when switching TO password mode (unless one exists);
  switching away clears it.
- `allow_remix` lets viewers duplicate the deck as a template — a virality
  lever, but also a copy lever. Ask, don't assume.
- Prefer `email` over `public` when the user cares about *who* viewed:
  anonymous public views can never become leads in `deckcp-analyze`.

## Report

After changes, `list_deck_access` again and summarize: who has what role,
what the gate is, and the share URL story ("anyone with the link can view" /
"viewers must enter an email" / "invite-only").

## Guardrails

- **Confirm before widening access**: making a deck `public`, adding an
  `owner`/`editor` grant, or enabling `allow_remix` — say what it exposes
  and get a yes.
- Sending invite emails (`notify: true`, the default) is outbound mail on
  the user's behalf — name the recipients before calling.
- Never set or echo a password the user didn't choose.
