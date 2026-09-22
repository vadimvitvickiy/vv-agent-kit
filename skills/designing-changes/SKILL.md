---
name: designing-changes
description: Use when asked to build, add or change behavior and the approach has not been agreed yet, when a request is open-ended or ambiguous about scope, or when an idea needs shaping into a design before any code is written.
---

# Designing changes

**Agree on what to build before building it.** The expensive failure is not a wrong line. It is a
correct implementation of the wrong thing, discovered when the human reads a finished diff — every
hour between the misunderstanding and that moment is spent on work that gets thrown away.

## Classify the request out loud

Before the first question, say which kind of request this is, so the human can correct it:

| Kind | What it is | What it produces |
|-|-|-|
| Spike | A feasibility question — "can we", "is it possible" | An answer. Anything built is labelled throwaway |
| Bounded | A scoped change to a flow that already exists in this repo | A short design in chat |
| Architectural | A new project or subsystem, or a change to how components fit or to an interface others depend on | A written design, then a plan |

**Bounded is a property of the repo, not of your familiarity.** Knowing what kind of app this is does
not make a change bounded; the flow being changed has to exist here, readable. A new project has no
existing flow, so it is never bounded.

When unsure between two kinds, take the heavier. The ratchet only turns one way: complexity found
mid-task upgrades the kind — stop and say so — and nothing downgrades.

## The artifact scales, the approval does not

A bounded design may be three sentences. It still ends with the human saying yes, and nothing is
implemented until they do. Presenting a design and starting on it in the same message is skipping the
gate, because the human's first chance to object arrives after the work exists.

"Too simple to need approval" is the exact case where an unexamined assumption costs the most: nobody
looks twice at the simple change, so the wrong assumption ships.

One exception is real. When the request already states what to change and where — a named function,
a named behavior, a named file — the request *is* the approved design. Asking the human to approve
what they just said is ceremony, not a gate.

## Understand before asking

- **Read before you ask.** Files, docs, recent commits. A question the code answers spends the
  human's attention on something you could have looked up.
- **Check the scope first.** A request that spans several independent subsystems needs decomposing
  before any detail is refined. Name the pieces and their order, then design the first one.
- **One question per message**, multiple choice where the options are knowable. A list of five
  questions gets answers to the easy ones and silence on the one that mattered.
- **Ask about purpose, constraints and what done looks like** — not about implementation details the
  design will settle anyway. Knowing what kind of app it is does not say why the human wants it.

Then **write your understanding back** in a short note: the outcome wanted, the constraints, what
success looks like — with what the human said kept apart from what you assumed. Invite correction
before treating it as the brief. When the request already states all of this, reflect it back rather
than asking the same questions again. Every later choice gets checked against this note, so its
accuracy matters more than its length.

## Offer approaches, not a verdict

Propose two or three approaches with their trade-offs, leading with the one you recommend and why. A
single design turns the review into approve-or-reject; alternatives expose the trade-off the human
would otherwise discover after it was made for them.

Strip every feature nobody asked for, from every approach. A design is easier to extend than to cut
back once code depends on it.

## Present the design in sections

Scale each section to its difficulty — a sentence where it is obvious, a few paragraphs where it is
not — and confirm each before moving on. A single wall of design gets approved in one skim.

Cover the boundaries, the data flow, what happens on failure, and how it will be tested. For each
unit, you should be able to say what it does, how it is used, and what it depends on. If a unit
cannot be understood without reading its internals, its boundary is in the wrong place.

In an existing codebase, follow its patterns. Improve what the change actually touches, when the
problem gets in the way of the work; propose nothing that does not serve the goal.

## Write it down when it is architectural

Save the agreed design where the project keeps them, or `.agents/plans/` when it names nowhere. Then
reread it for:

- placeholders, "TBD", or a section left vague;
- two sections that contradict each other;
- a requirement readable two ways — pick one, and say which;
- scope too large for one plan, which means it needs splitting.

Ask the human to review the file before anything is implemented. The plan that follows is
`vvkit:planning-changes`.

**Each approval covers the stage that was shown, and nothing after it.** Agreeing to the design in
conversation permits writing it down. Approving the written design permits writing the plan.
Approving the plan, and choosing how it runs, permits implementation. An approval of an idea does
not approve artifacts that do not exist yet; resume at the earliest stage still unapproved. Reading
the code is allowed at any stage.

## Before implementing

- [ ] The kind was stated, and the human had the chance to correct it
- [ ] Your understanding was written back, with assumptions marked, and corrected where wrong
- [ ] The human said yes to the design, after seeing it
- [ ] Every open question that changes the design has an answer
- [ ] Nothing in the design goes beyond what was asked for
- [ ] For architectural work, the design is written down, reviewed, and a plan approved
