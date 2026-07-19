---
name: deckcp-capture
description: Capture a person into the DeckCP CRM from anywhere — a conversation, a business card or badge photo, a voice memo, a GitHub profile, an email signature — even with no email address. Use when the user says "add this person", "I just met someone", "capture this card", "save this contact", or mentions a person who should be in the pipeline. Requires the DeckCP MCP connected and org access.
argument-hint: "[--name <name>] [--email <email>] [--company <co>]"
---

# Capture a Contact (get them in the CRM before you forget them)

A lead you didn't write down is a lead that doesn't exist. This skill turns
any trace of a person — half a name, a card photo, a memo, a commit — into a
CRM row the org can work.

## Step 1 — extract from whatever the user has

- **They tell you** — name, company, context. Enough.
- **A photo** (business card, badge, screenshot) — read it: name, title,
  company, email, phone/handles.
- **A voice memo** — `deckcp-voice-memos` finds the conversation; pull the
  person out of the transcript ("the founder from the Tuesday call").
- **GitHub** — `github-lookup` resolves a username/commit/email to a name,
  company, and public email.
- **An email signature / LinkedIn text** — parse it.

**Email is optional.** Don't stall the capture hunting for one — a
name+company row with a note beats nothing. Handles go in `channels`
(`whatsapp`, `line`, `messenger`, `linkedin`).

## Step 2 — check for an existing row

```
list_leads { search: <email> }     # search matches on email
get_lead { email }                 # if found — see their history first
```

- Email known + row exists → `create_contact` upserts onto it anyway (by
  email), or use `update_lead` when you're changing stage/note on someone
  with deck activity.
- No email → search is blind; scan `list_leads` output for the name/company
  before creating, so the org doesn't get twins.

## Step 3 — create

```
create_contact {
  name, company, title,
  email?,                      # optional; dedupes-by-email when present
  stage?,                      # default "new"
  note?,                       # WHERE you met + WHAT they cared about + next step
  assigned_to?,                # a teammate's email
  channels?: { whatsapp?, linkedin?, line?, messenger? }
}
```

The `note` is the capture's real payload — context decays in a day. Write it
like a handoff: *"Met at Techsauce 7/19, ex-Grab ops, asking about the
analytics tier, wants intro to a TH distributor. Follow up by Friday."*

## Step 4 — route the follow-up

- Send the deck → `deckcp-share` (an `email`-gated link makes their views
  show up on this same CRM row).
- Write the note → `deckcp-email` (dry-run first, always).
- Later: `deckcp-analyze` / `get_lead` shows whether they actually looked.

## Guardrails

- Capture what the person gave (a card is consent to be a contact); don't
  enrich from sources the user didn't provide.
- Never invent an email — a wrong one silently splits the person into two
  rows forever.
- One person per capture; batches (a stack of cards) → one create_contact
  each, then one summary.
