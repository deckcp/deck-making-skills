---
name: deckcp-voice-memos
description: Search your voice-memo transcripts semantically and turn what you find into deck material, CRM contacts, or recalled facts — founder pitches, due-diligence calls, meetings, ideas said out loud. Use when the user says "search my voice memos", "what did I say about...", "find that call with...", "I recorded a memo about this", or wants real quotes/details from past conversations in a deck or follow-up. Requires the DeckCP MCP connected.
argument-hint: "[--query \"...\"] [--full]"
---

# Mine Voice Memos (semantic recall → deck material, contacts, facts)

Things said out loud are the rawest source material there is — pitches you
gave before slides existed, what a customer actually objected to, the number
someone quoted on a call. This skill finds it and routes it.

## Step 1 — search by meaning, not keywords

```
search_voice_memos { query: "...", match_count?: 1-25, full_transcript?: bool }
```

Returns each match with **date, place, topic, and a ~600-char excerpt**,
ranked semantically — "EV delivery truck specs" finds the memo that never
says "specs".

Search like a researcher:

- **Several angles beat one**: for "the pitch to the logistics customer" try
  the company name, the problem discussed, the place you met, the date range
  in words. Different phrasings surface different memos.
- **Excerpts first.** Only re-fetch the winners with `full_transcript: true`
  — full transcripts are long; don't pull eight of them to use one.

## Step 2 — route what you found

**→ Deck material** (the killer use): a verbal pitch is a pre-interview.
Extract the audience, the ask, the proof, the objections that came up — feed
it to `deck-interview` as raw input or straight into a `brief.json`. Real
phrasing from a real conversation beats copy invented at a keyboard; a
number or story from a call is `evidence` for `deck-outline`.

**→ A contact**: someone in the memo belongs in the pipeline — hand the
name/company/context to `deckcp-capture`. The memo's date+place makes the
capture note ("met at —, discussed —") for free.

**→ A recalled fact**: sometimes the answer is just the answer — what did
the founder say the CAC was? Quote the excerpt, cite the memo's date/place,
done.

## Step 3 — report

Lead with what was found, not the search process: the memo(s), date, place,
one-line gist each, then the extracted payload (the brief fragment, the
contact, the fact). Offer the route, don't auto-run it.

## Guardrails

- These are **personal recordings** — private by default. Quote into decks,
  emails, or CRM notes only what the user has seen and approved; never paste
  a full transcript anywhere outward-facing.
- Other people on these recordings didn't write the transcript — treat
  their words as your notes about the conversation, not as quotable
  statements they signed off on.
- A transcript is a lossy record: verify load-bearing numbers with the user
  before they go on a slide.
