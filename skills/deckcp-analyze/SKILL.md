---
name: deckcp-analyze
description: Check a DeckCP deck's audience analytics — who viewed it, engaged time, per-slide dwell and drop-off — and turn that into concrete follow-ups and deck fixes. Use when the user says "check my analytics", "who viewed my deck", "how is the deck doing", "where do people drop off", or after sending a deck out. Requires the DeckCP MCP connected and owner/org access to the deck.
argument-hint: "[--deck <slug>] [--lead <email>]"
---

# Deck Analytics (read tools + a short interpretation — minimal tokens)

The numbers come from one tool call; your job is the *reading* — where the
story loses people, and which viewer deserves a follow-up today.

Access note: analytics is an **owner / org-member** surface. A viewer grant
or a public link is enough to *see* the deck but never its analytics — if
the call is refused, that's why.

## Step 1 — pull the deck's numbers

```
get_deck_analytics { deck_slug }                        # sessions_limit: up to 200
```

You get: session count, identified vs anonymous viewers, total/average
engaged time (idle-trimmed — real attention, not open tabs), completions,
the **per-slide dwell curve**, and recent sessions.

## Step 2 — read the dwell curve like an editor

The dwell curve is a critique of the deck written by its audience:

- **Cliff mid-deck** — the slide before the cliff is where the argument
  loses them. Name it. That's the first `deckcp-edit` / `deck-critique`
  target.
- **Long dwell on a dense slide** — could be interest, could be confusion.
  Cross-check with completion: high dwell + high drop-off = confusion.
- **Skimmed proof slides** — proof that isn't landing might as well be cut.
- **Low completion overall** — the deck is too long for how it's sent, or
  the hook isn't earning the read (`deck-outline` again, not more polish).

Anonymous-heavy audience? The deck's gate is `public` — suggest
`deckcp-share` set it to `email` so future views are identified.

## Step 3 — the people, not just the curve

Identified viewers are leads. For the pipeline view:

```
list_leads { search?, stage?, limit? }        # the org's lead board
get_lead { email }                            # one person: per-deck engagement,
                                              # email journey, activity timeline
```

`get_lead` shows visits, idle-trimmed time per deck, per-slide dwell, and
whether follow-up emails were opened. A lead who viewed twice and stalled on
the pricing slide is a *specific* conversation, not a stat.

Update CRM state as the user works the list:

```
update_lead { email, stage?, note?, assignee? }
```

## Step 4 — report and route

Keep the report short and decision-shaped:

1. **Headline numbers** — sessions, identified/anonymous, avg engaged time,
   completions.
2. **The curve's verdict** — the one or two slides the data indicts.
3. **Who to follow up with today** — top 2–3 engaged viewers and why.

Then route: *"`deckcp-email` to send the follow-up, `deckcp-edit` to fix the
drop-off slide, `deck-critique` if the whole spine needs a pressure-test."*

## Guardrails

- Small numbers are noise: don't narrate trends off 3 sessions — say so.
- Idle-trimmed time is the honest metric; never report raw open-duration as
  engagement.
- Analytics contain viewer emails — treat them as CRM data, not content to
  paste into slides or share externally.
