# nana — North Star: Loop Engineering

*Working vision, written 2026-07-01. Plain language on purpose — a shared reference so we stop rethinking the direction from scratch every time. It will change as we learn; when it does, we update this doc. Where something is decided direction it's stated plainly; where it's a bet or something we've actually tested, it's marked.*

## The one-line version

We adopt **loop engineering** (Andrew Ng's framing): organize the whole system around three loops, and move the human *up and out* of the hands-on work — so a small amount of high-quality human judgment can direct a large amount of work.

## The three loops

Each loop is a **role**, not a fixed person or model — who fills the role depends on the work.

**Loop 1 — the worker (developer / engineer).**
The hands-on work: writing, trying, testing, fixing, fast. Who does it depends on how hard the task is — a cheap model that runs on your own machine (free to run) for routine work, or a strong model (Claude) for complex work. The worker runs mostly on its own, behind a safety check.

**Loop 2 — the product owner / manager.**
Reviews the worker's output and gives clear feedback and direction. This is the highest-leverage role. This is where the human lives — and where Claude can also sit when it's coaching a cheaper worker.

**Loop 3 — the user.**
The human as the actual user, giving real-world feedback about what works — which feeds back into the direction.

**The key move:** the human moves *up and out* of Loop 1 — spending their time steering (Loop 2) and using the product (Loop 3), and letting the workers build.

## Who fills the roles (flexible, by difficulty)

- **Routine work:** a cheap model is the worker (Loop 1); Claude or the human steers (Loop 2).
- **Complex work:** Claude is the worker (Loop 1); the human steers (Loop 2).
- **Always:** the human is the product owner (Loop 2) and the user (Loop 3).

Capability flows downhill — **human → Claude → cheaper worker** — each layer coaching the one below. The human's input is the rarest and highest-value; the cheap worker does the volume.

**A bet we're making here:** good steering can lift a weaker worker to handle more than it could alone. Our own past experiments point to an important nuance — the lift comes mostly from *concrete* feedback (showing the worker exactly where it broke, with an example), **not** from instructions alone (just naming the rule was nearly useless). And *how much* a weak worker can be lifted — and whether it holds across the full human→Claude→cheap-worker chain — is untested. So: build the coaching around concrete, checkable feedback, and treat the size of the lift as a bet, not a proven fact.

## The safety check, and why leaving Loop 1 is possible

*(This is connective reasoning, not part of the stated vision — but it's why the vision is buildable.)*

The safety gate we've already built is what makes leaving Loop 1 *safe*: the worker acts behind a check, so risky moves get caught. Today that gate checks **every** action. The vision needs a smarter gate that only interrupts for the **rare** risky or irreversible action and lets routine work flow — that selective behavior is part of the Loop-2 work still to build, not something that exists yet.

## Two engines behind the loops

1. **Feedback engine (Loops 2–3):** the screens and tools for reviewing work and giving steering feedback. This becomes the new center of the product. It's not only a new screen — the **decision-making frameworks we already have** (how the system proposes a plan, surfaces assumptions, asks for a call) should be re-aimed to serve this steering role too, not just approve-each-action.

2. **Knowledge engine:** turns work into reusable knowledge that sharpens future direction. The YouTube research tool is our first prototype. **Honesty caveat:** where this pays off is sharpening the *human's* direction and coaching a *cheaper/weaker* worker. Feeding stored knowledge back to a *strong* model (Claude) has repeatedly shown little-to-no benefit in our own tests — a strong model tends to re-work things out on its own. So aim the stored knowledge at the human and the cheap workers, and treat "this knowledge compounds everywhere" as a bet, not a given.

## What's built vs. what's next

**Built — the hard, security-critical part:**
- The Loop-1 foundation: an engine that keeps risky actions behind a safety check and works with any AI model, with a free-to-run local model as the default, in a desktop app. This is the "worker behind a check" the vision needs.

**Early prototype:**
- The knowledge engine (YouTube research). Narrow today; needs generalizing.

**Barely built / not built — the new work:**
- The **feedback / steering screen.** Today's screen is built for approving each action (a Loop-1 shape), not for reviewing-and-steering (the Loop-2 shape the vision needs).
- **Adjusting the loops themselves** — the loop-engineering design work.

## The build decision (settled)

**We build on the existing foundation — not a restart.** The Loop-1 foundation (safety check + any-model engine) is the hardest part and it's done. What changes is the *center* of the product: from "drive one agent and approve its moves" to "give feedback and shape loops." That deserves a bigger name and scope than the developer tool it started as — but it rides the same engine.

**Immediate next step (decided 2026-07-01):** the feedback-screen sketch is done — see [[manager-desk-sketch]] — and feasibility is confirmed against the code (an additive view on the existing engine; the rebuild contingency is ruled out). **First build = decision-capture** (reconstruct "the calls the worker made" — the riskiest new piece, since the whole desk's trust rests on it). No de-risking slice: feasibility is proven and value is judged by feel, so there is nothing a slice would prove. Continue in a new session.

## Principles and tensions to hold

- **Every reviewable thing must be *feelable* — not just described.** Some calls can't be made from a summary; you have to see it, run it, feel the consequence. So each item on the manager's desk has a *feel it* option that drops into the real thing — run the change, click the new screen, fire the rule on real cases, see a threshold's effect on real data. This is a *build rule*, not a nice-to-have: every reviewable component ships with its felt mode from the start. (Same felt-quality bar we already hold for the product itself — now pointed at the review surface.)
- **Feedback beats instructions — when it's concrete.** Our past tests here: concrete feedback (a failing test, a specific example of what broke) lifts a worker's quality; just naming the rule was nearly useless. One caution: a worker *could* in principle game the check (pass it without really doing the work) — the real worker didn't, but keep the checks concrete and verifiable rather than assuming gaming can't happen.
- **Spend where it compounds; economize where it doesn't.** Spend generously on the loops that build lasting value (good feedback, real knowledge); economize on the disposable build churn. Money spent building is used-and-gone; money spent on feedback and knowledge can keep paying back.
- **Quality feedback costs speed — that's the trade.** Reviewing properly slows raw throughput. The chain buys it back: the human's slow, high-value input gets amplified down to the workers. *(The size of that amplification — "a little judgment moves a lot" — is the central bet; we haven't measured the multiplier.)*
- **The human keeps one small slice of Loop 1.** For risky or irreversible actions — especially in a high-stakes domain — the human (or the gate) stays in. That slice is small by design; the safety check keeps it that way.

## Open questions / next steps

1. **Feedback-screen sketch — done** ([[manager-desk-sketch]]); feasibility confirmed (additive view on the existing engine). First build = decision-capture; no de-risking slice.
2. **Knowledge engine → loops** — generalize the YouTube prototype from "research a topic" into "turn our own work into reusable knowledge," aimed at the human and the cheap workers.
3. **The unit of review — decided:** a *round* or a *whole job*, never every decision, chosen by complexity × cost of error (simple/low-stakes → the whole job at the end; complex/high-stakes → round by round).
4. **Measurement** — some of this can only be judged by the human's own felt sense of control and leverage, not a metric. That's allowed — and the core "a little judgment moves a lot" multiplier is the main thing we'd love to measure but may not be able to.
