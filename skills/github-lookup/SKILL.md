---
name: github-lookup
description: Look up a person from GitHub — by username, by a commit SHA, or by email — and get their name, profile, and (when public) contact email. Use when the user says "who is <login>", "look up the author of <commit>", "find this person on GitHub", or needs a contact before emailing them. Uses the authenticated gh CLI.
argument-hint: "(--user <login> | --commit <sha> [--repo owner/name] | --email <email>)"
---

# GitHub people lookup (script-first, zero tokens)

Resolve a real person behind a GitHub username, a commit, or an email address —
their name, company, location, profile, and public email if they expose one.
Pairs with `deckcp-email`: look someone up here, then email them.

## Why this is script-first

It's deterministic API/CLI work — `gh api` + a little JSON formatting. No model
judgment needed to fetch a profile, so `scripts/gh-person.sh` does it for free.
Bring judgment only to *what you do with* the result (whether/how to reach out).

## Prerequisite

The `gh` CLI, authenticated (`gh auth status` should be green). The script fails
with a clear message if gh is missing or unauthenticated.

## Usage

**By username** — the profile card:

```bash
bash scripts/gh-person.sh --user torvalds
```

**By commit** — the author's git email (always available locally) plus, if the
commit is linked to a GitHub account, that profile too. Auto-detects the repo
when run inside one; pass `--repo owner/name` otherwise:

```bash
bash scripts/gh-person.sh --commit db3d6ac
bash scripts/gh-person.sh --commit db3d6ac --repo deckcp/deck-making-skills
```

**By email** — best-effort: finds a public commit authored by that address and
reads its GitHub login:

```bash
bash scripts/gh-person.sh --email someone@example.com
```

## What you get

```
Name:     Linus Torvalds
Login:    torvalds
Email:    (not public — use --commit for a commit-author email)
Company:  Linux Foundation
Location: Portland, OR
Repos:    12 public · Followers: 312252
Profile:  https://github.com/torvalds
```

## Getting a usable email (important)

GitHub profiles rarely expose a public `email`. The **reliable** source of a
contact address is the **commit author email** — so when a profile's email is
private, fall back to `--commit <sha>` on one of their commits (or `git log
--author=<login> --format='%ae'` in a repo they contributed to). Note that many
contributors use GitHub's `…@users.noreply.github.com` masked address on public
commits — that can't receive mail.

## Guardrails

- A private profile or a masked/no-reply commit email means you genuinely don't
  have a way to reach them — say so; don't guess or construct an address.
- This reads public GitHub data. Use it to find a legitimate contact, not to
  scrape or mass-harvest people.
- Hand a confirmed address to `deckcp-email` (dry-run first) to actually write.
