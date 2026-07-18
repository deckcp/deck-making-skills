---
name: deck-interview
description: Interview a founder, salesperson, or BD lead about their deck before any slides exist — audience, goal, the ask, proof, and narrative — and push back on weak positioning. Use when the user says "help me with my pitch deck", "interview me", "I need a deck for investors/a customer/a partner", or before building/outlining any deck. Emits brief.json.
argument-hint: "[--out ./deck-brief] [--type investor|sales|partnership|internal]"
---

# Deck Interview (main-loop model — this is the product)

Before a single slide exists, get the story straight. This skill interrogates the
user about who the deck is for, what it must make happen, and whether their
positioning actually holds up — then writes a structured `brief.json` that
`deck-outline` and `deckcp-build-deck` consume.

## Why this is a main-loop step (not Haiku, not a script)

The value here is *judgment under conversation*: hearing a vague answer and knowing
which follow-up exposes the weak spot, noticing when the "ask" is buried, telling a
founder their differentiation is a feature not a moat. That is exactly what a
downgraded model does badly. **Run this in the current session's model** — do not
spawn a Haiku subagent for the interview. Scripts only scaffold the output
(`scripts/init-brief.sh` writes the empty schema); the thinking is yours.

Your job is not to be a friendly form. **You are a sharp advisor who has seen a
thousand decks fail.** Be warm but honest. If the positioning is weak, say so and
propose a stronger frame — don't transcribe a bad pitch into a clean brief.

## Step 0 — scaffold

```bash
bash scripts/init-brief.sh --out ./deck-brief
```

This creates `./deck-brief/` and writes a `brief.json` template you fill in as the
interview proceeds. Zero tokens.

## Step 1 — establish the frame (one question at a time)

Ask these in order, using `AskUserQuestion` where the answer is a choice and open
chat where it needs a story. **Do not dump all questions at once** — react to each
answer, dig where it's thin.

1. **Deck type & context.** Investor raise, sales pitch, partnership, internal?
   What's the setting — sent as a link and read alone, or presented live? (This
   changes everything about density and narration.)
2. **The single audience.** Who is the *one* decision-maker? Their role, what they
   already believe, what they're skeptical of. "Investors" is not an answer — a
   seed-stage generalist VC and a strategic corp-dev lead need different decks.
3. **The one outcome.** Finish this sentence for them: *"This deck succeeds if,
   after reading it, they ______."* If they can't, that's the first problem to fix.
4. **The ask.** What specifically are you asking for — $2M seed, a pilot, a signed
   LOI, an intro? Vague asks ("support", "partnership") get a pushback.

## Step 2 — pressure-test the substance

For each, capture the answer AND your assessment:

- **Problem.** Who hurts, how much, how often? Is it a painkiller or a vitamin?
- **Insight / why now.** What do they know that the audience doesn't? Why is this
  possible/urgent *now* and not two years ago?
- **Solution.** In one sentence a non-expert repeats correctly. If it takes a
  paragraph, push for the sentence.
- **Proof.** Traction, revenue, pilots, waitlist, letters of intent, a working
  demo — anything real. Distinguish *evidence* from *hope*. Flag hopes as hopes.
- **Differentiation.** Why won't the obvious incumbent/competitor just do this?
  A feature is not a moat. Name the actual defensibility or admit it's speed.
- **The team / unfair advantage.** Why these people.
- **Objections.** What are the top 2–3 reasons a smart skeptic says no? A deck that
  doesn't preempt its own objections loses in the room.

## Step 3 — push back, then confirm

Before writing the brief, tell the user — plainly — the **two or three things that
are weakest** and how you'd reframe them. Examples of the register:

> "Your 'ask' right now is 'let's explore working together.' That reads as no
> conviction. What's the smallest concrete commitment you actually want — a 30-day
> paid pilot? Lead with that."

> "You have a vitamin, not a painkiller, unless you can show what it costs them to
> keep doing nothing. Do you have that number?"

Let them respond and revise. Only then finalize.

## Step 4 — write brief.json

Fill `./deck-brief/brief.json`. Schema:

```json
{
  "deck_type": "investor | sales | partnership | internal",
  "setting": "sent-as-link | presented-live",
  "audience": { "who": "", "believes": "", "skeptical_of": "" },
  "success_outcome": "one sentence: after reading, they ___",
  "ask": "the specific, concrete ask",
  "problem": "", "insight": "", "solution_one_sentence": "",
  "proof": [{ "claim": "", "kind": "evidence | hope" }],
  "differentiation": "", "unfair_advantage": "",
  "objections": [{ "objection": "", "answer": "" }],
  "assessment": {
    "strongest": "", "weakest": "", "reframes_applied": ["", ""]
  },
  "voice": "optional: link to voice.json from deck-writing-samples"
}
```

Report a one-paragraph summary of the brief and hand off: *"Run `deck-outline` to
turn this into a story spine, or `deckcp-build-deck` to go straight to slides."*

## Guardrails

- One decision-maker, one outcome, one ask. If the user insists on many, help them
  pick the primary and note the rest as secondary.
- Never invent proof. If they have none, the brief says `"proof": []` and the
  assessment flags it — that's a real finding, not a gap to paper over.
- Keep the brief honest: `assessment.weakest` must name something real.
