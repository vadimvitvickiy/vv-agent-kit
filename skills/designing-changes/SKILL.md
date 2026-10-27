---
name: designing-changes
description: Use when asked to build, add or change behavior and the approach has not been agreed yet, when a request is open-ended or ambiguous about scope, or when an idea needs shaping into a design before any code is written.
---

# Designing changes

**Agree on what to build before building it.** The expensive failure is a correct implementation of
the wrong thing, found when the human reads a finished diff.

## Classify the request out loud

Say which kind it is before the first question, so the human can correct it:

| Kind | What it is | What it produces |
|-|-|-|
| Spike | A feasibility question — "can we", "is it possible" | An answer. Anything built is labelled throwaway |
| Bounded | A scoped change to a flow that already exists in this repo | A short design in chat |
| Architectural | A new project or subsystem, or a change to how components fit or to an interface others depend on | A written design, then a plan |

- **Bounded is a property of the repo, not your familiarity.** The flow must exist here, readable. A
  new project is never bounded.
- Unsure between two kinds: take the heavier. Complexity found mid-task upgrades the kind — stop and
  say so. Nothing downgrades.

## The artifact scales, the approval does not

- A bounded design may be three sentences. It still ends with the human saying yes, and nothing is
  implemented until then. Presenting a design and starting on it in one message skips the gate.
- "Too simple to need approval" is where an unexamined assumption costs most — nobody looks twice.
- **Exception:** a request that already names what to change and where — a function, a behavior, a
  file — *is* the approved design. Asking to approve it is ceremony.

## Understand before asking

- **Read before you ask** — files, docs, recent commits. Do not spend the human's attention on what
  the code answers.
- **Launch a survey as you start reading:** `vvkit:architecture-surveyor` in the background, with a
  file path for its report. It looks sideways — sibling features, type owners, how an abstraction was
  last extended. Read it before proposing. Skip only for a one-sentence change.
- **Check the scope.** Several independent subsystems: name the pieces and their order, design the
  first.
- **One question per message**, multiple choice where possible. Five questions get the easy ones
  answered.
- **Ask about purpose, constraints and what done looks like** — not details the design settles.
- **Write your understanding back**: outcome, constraints, success — what the human said kept apart
  from what you assumed. Invite correction. If the request already states it all, reflect it back.

## Say the premises out loud

- A premise is what was already true and nobody said. Nothing checks it, so rounds of careful design
  on a wrong one deliver the wrong thing more convincingly each time.
- Ask **what would have to be true for this to be the right approach?** — who needs it, what the
  problem costs today, what it is assumed to be free of. Write the answers in the note.
- Measure a premise that is cheap to measure. Compensation code for an unmeasured problem is the
  typical casualty.
- **Premises stay live after approval.** Re-read them when fixes keep landing on new variants of one
  problem, or when work goes unusually smoothly.

## Shape the design

- **Data shape first.** Get the types and their states right before the logic; make illegal states
  unrepresentable rather than checked for.
- **Parse at the boundary, trust inside.** Validate outside data once, where it enters; keep business
  logic in pure functions behind that boundary.
- **Redesign, do not bolt on.** Ask what you would have built had the requirement been there from the
  start; deliver that in pieces. A requirement bolted onto the old shape leaves both shapes behind.
- **Subtract before you add.** Look for complexity the change lets you remove first.
- **Operations that can be retried or interrupted are idempotent** — run twice, or after a crash
  halfway, they end in the same state.
- **Shared mutable state gets one writer**, enforced by the structure. If two parts do not need the
  same mutable thing, give each its own.
- **Extend, never disguise data.** A function that takes another type is asking for a sibling that
  takes yours. Hand-building another layer's type from data that never came from there invents fields
  everything downstream trusts.
- In an existing codebase, follow its patterns. Improve what the change touches when it gets in the
  way; propose nothing that does not serve the goal.

## Offer approaches, then present in sections

- Two or three approaches with trade-offs, recommended one first, with why. One design turns review
  into approve-or-reject.
- Strip every feature nobody asked for. A design is easier to extend than to cut back.
- Present in sections sized to difficulty, confirming each. A wall of design gets approved in one skim.
- Mark each choice a **decision** (weighed against a named alternative) or a **default** (something had
  to be picked). An unmarked default soon looks like a property of the problem.
- Cover boundaries, data flow, failure behavior and testing. Each unit: what it does, how it is used,
  what it depends on. A unit you cannot understand without its internals has its boundary misplaced.

## Write it down when it is architectural

- Save it where the project keeps designs. None named: `.agents/plans/`, only if
  `git check-ignore -q .agents/plans` succeeds; otherwise ask.
- Reread for placeholders or "TBD", contradicting sections, a requirement readable two ways (pick one,
  say which), and scope too large for one plan.
- Ask the human to review the file. The plan follows — `vvkit:planning-changes`.
- **Each approval covers the stage shown, nothing after it.** Agreement in chat permits writing the
  design; an approved design permits the plan; an approved plan, with how it runs, permits code.
  Resume at the earliest unapproved stage. Reading code is allowed at any stage.

## Before implementing

- [ ] The kind was stated, and the human could correct it
- [ ] Your understanding was written back, assumptions marked, corrected where wrong
- [ ] The human said yes to the design, after seeing it
- [ ] Every open question that changes the design has an answer
- [ ] Nothing in the design goes beyond what was asked
- [ ] For architectural work, the design is written, reviewed, and a plan approved
