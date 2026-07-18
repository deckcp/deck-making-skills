---
name: deckcp-email
description: Send an email to a contact (a DeckCP lead, or anyone) via the Zavu messaging API — with cc, reply-to, and a safe dry-run preview. Use when the user says "email <person>", "email this lead", "send a follow-up", or "email the author of <commit>". Needs ZAVU_API_KEY in the environment or .env.local.
argument-hint: "--to <email> --subject \"...\" (--text \"...\" | --text-file body.txt) [--cc <email>] [--reply-to <email>] [--send]"
---

# Email a contact via Zavu (script-first, dry-run by default)

Send transactional email through Zavu (`https://api.zavu.dev/v1/messages`) —
the same sender DeckCP uses for share/follow-up mail. This is the outbound half
of working the CRM: pull a contact, write a message, send it, log it.

## Why this is script-first

Composing the message is judgment (do that in the main loop). *Sending* it is a
solved HTTP POST — `scripts/zavu-send.js` does it deterministically, reads the
key from the env / `.env.local`, and **defaults to a dry run** so nothing leaves
the building until a human has seen the exact recipient, cc, and body.

## Safety first — this is outbound, irreversible email

- **Always dry-run first.** Run without `--send` to print the full payload
  (recipient, cc, reply-to, body; the API key is redacted). Show it to the user.
- **Send only on explicit go-ahead** for the specific recipient(s). Re-confirm if
  the recipient or body changed since the last preview.
- **One person, real intent.** This skill is for genuine 1:1 / small sends
  (a follow-up, a request, a reply). It is NOT a bulk blaster — do not loop it
  over a lead list to cold-email people. Respect unsubscribes and don't re-email.
- Never invent an address. If you don't have the recipient's email, find it
  (ask, or look it up — e.g. `git show -s --format='%ae' <commit>` for a commit
  author) and confirm it before sending.

## Step 1 — figure out the recipient

- **A DeckCP lead / contact:** `list_leads` / `get_lead` to get the person and
  their email (and the context — which deck they viewed, their stage).
- **A commit author:** `git show -s --format='%an <%ae>' <sha>`.
- **Someone the user names:** use the address they give, or search their mail.

## Step 2 — compose, then dry-run

Write the subject + body (plain text). Then preview — nothing sends here:

```bash
node scripts/zavu-send.js \
  --to person@example.com \
  --cc me@example.com \
  --reply-to me@example.com \
  --subject "Subject line" \
  --text "Body line 1

Body line 2"
```

For a longer body, put it in a file and pass `--text-file body.txt`. Show the
printed payload to the user and get an explicit yes.

## Step 3 — send

Re-run the **exact same command with `--send` appended**:

```bash
node scripts/zavu-send.js --to person@example.com --cc me@example.com \
  --reply-to me@example.com --subject "…" --text "…" --send
```

On success it prints `sent ok (2xx)`; on failure it exits non-zero with the
Zavu status + error. Report the outcome plainly — if it failed, say so and show
the error, don't claim it sent.

## Options

| Flag | Meaning |
| --- | --- |
| `--to` | Recipient email (required) |
| `--subject` | Subject line (required) |
| `--text` / `--text-file` | Body, inline or from a file (one is required) |
| `--cc` | Cc an address; repeat for several (e.g. `--cc me@x.com`) |
| `--reply-to` | Where replies should go (usually the user) |
| `--sender` | A Zavu sender *ID* (from /v1/senders); default = project default sender |
| `--send` | Actually send. Omit for a dry run. |

## Setup / config

- **`ZAVU_API_KEY`** — required. Read from the environment or a `.env.local` /
  `.env` in the working dir (the deckcp repo already has it). For use in another
  project, the user supplies their own Zavu key.
- **`ZAVU_SENDER`** (optional) — a Zavu sender ID; omit to use the project's
  default verified sender. The send is from that verified-domain address, not
  from the user's personal Gmail — so set `--reply-to` to the user so replies
  come back to them.
- **cc caveat:** cc is passed to the Zavu API as a `cc` field. If a send needs a
  guaranteed cc and you're unsure it landed, confirm with the recipient or send
  the cc address a copy directly.

## Guardrails

- Dry-run → human yes → `--send`. Never skip the preview for a first send.
- Report send failures honestly (the script exits non-zero — surface it).
- Don't use this to bulk-mail leads or evade unsubscribe.
