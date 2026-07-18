---
name: deck-outline
description: Turn a deck brief into a story spine before any slides — problem → insight → solution → proof → ask — so the narrative is right before design starts. Use when the user says "outline my deck", "what slides do I need", "help me structure the pitch", or right after deck-interview. Reads brief.json, emits outline.json + outline.md.
argument-hint: "[--brief ./deck-brief/brief.json] [--out ./deck-brief]"
---

# Deck Outline (outline-first, main-loop model)

A deck fails at the story level before it ever fails at the design level. This
skill builds the **narrative spine** from the brief so every slide earns its place,
then hands a slide-by-slide outline to the build step.

## Why this is a main-loop step

Sequencing an argument — which claim must land before the next is believable, where
the proof goes, how to open so a skeptic keeps reading — is judgment, not
templating. Run it in the current session's model. A script (`scripts/scaffold-outline.sh`)
only writes the empty structure; you fill the story.

## Step 0 — read the brief

```bash
cat ./deck-brief/brief.json
```

If there is no brief, run `deck-interview` first (or interview inline). Pay special
attention to `audience`, `ask`, `assessment.weakest`, and `objections` — the
outline must *route around the weakest points and preempt the objections*, not
ignore them.

## Step 1 — pick the spine

Default spine (adapt to deck type; don't apply mechanically):

1. **Hook** — the one line that makes them lean in. Often the insight or a
   startling number, not "Hi, we're X."
2. **Problem** — who hurts, how much. Make it their problem, felt.
3. **Insight / why now** — the thing you know that they don't; why now.
4. **Solution** — the one-sentence solution, then how it works, briefly.
5. **Proof** — traction/evidence. Strongest proof gets its own slide.
6. **Why you win** — differentiation / unfair advantage / team.
7. **The ask** — specific, concrete, singular. This is the destination; every
   prior slide should make it feel inevitable.

Variants:
- **Sales**: Problem → Cost of inaction → Solution → Proof (case study) → Pricing →
  Next step. Lead with the buyer's pain, not your company.
- **Partnership**: Shared goal → Why you two → What each brings → The proposal →
  Ask. Frame it as mutual, not a favor.
- **Live vs. sent-as-link** (from `brief.setting`): live decks can be sparse (you
  narrate); link decks must be self-explaining — more words per slide, clearer
  headlines-as-conclusions.

## Step 2 — write slide headlines as conclusions

The single highest-leverage move: **every slide's headline states the takeaway**,
not the topic. "Market" → "The wedge is a $4B niche nobody serves well." A reader
who skims only the headlines should get the whole argument.

For each slide capture: `purpose`, `headline` (the conclusion), `key_points`
(2–4 max), `evidence` (which proof from the brief, if any), and `visual` (what
carries it — chart, diagram, photo, product shot).

## Step 3 — cut

Ruthlessly. A seed deck is ~10–12 slides, a sales deck ~8–10. If a slide doesn't
move the audience toward the ask, it's an appendix slide or it's cut. Tell the user
what you cut and why.

## Step 4 — scaffold + write

```bash
bash scripts/scaffold-outline.sh --out ./deck-brief
```

Then fill `./deck-brief/outline.json`:

```json
{
  "deck_type": "", "audience": "", "ask": "",
  "spine": "the variant you chose and why",
  "slides": [
    {
      "n": 1, "purpose": "hook",
      "headline": "conclusion, not topic",
      "key_points": ["", ""],
      "evidence": "which proof, or null",
      "visual": "chart | diagram | photo | product | none"
    }
  ],
  "cut": ["what you removed and why"]
}
```

Also render a human-readable `outline.md` (headline per slide + key points) so the
user can eyeball the flow.

## Step 5 — read it back as a story

Read the headlines aloud in order. If they don't form a coherent argument on their
own, the outline isn't done — fix the sequence before handing off. Then:
*"Run `deckcp-build-deck` to generate slides from this, or `deck-critique` later to
pressure-test the built deck."*

## Guardrails

- Headlines are conclusions, not labels. Enforce this every slide.
- The ask appears once, concretely, at the end. No burying it mid-deck.
- Respect `brief.assessment.weakest` — the outline should strengthen or sidestep it,
  never lean on it.
