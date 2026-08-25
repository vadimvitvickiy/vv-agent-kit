# Architecture constraints

Only what cannot be derived by reading the code. No directory tree, no file counts, no
per-directory descriptions — `ls`, `grep` and the generated map cover those, and a hand-maintained
copy goes stale and then misleads.

Delete any section below that does not apply. An empty section is better than an invented one.

## Layering rule

{{LAYERING_RULE}}

State which components may depend on which, and what breaks if the order is inverted. The graph
itself is in the manifest; the *rule* is not.

## Frozen names

Identifiers that cannot be renamed without breaking existing installs, stored data, or published
contracts — and what breaks.

## Name mismatches that will trip you

| You look for | It is actually |
|-|-|

## Generated — never hand-edit

| Path | Produced by | Tracked |
|-|-|-|

Note any deliberate exception, such as a generated file that *is* committed.

## Known drift — do not copy

Places where the code diverges from the documented pattern, so nobody copies the wrong example.

## The generated map

`.agents/state/map.xml` — targets from ground truth plus the most-referenced type signatures, inside
a token budget. Regenerate with `scripts/map.sh`; it is gitignored and disposable. Read it before
fanning out searches, and never edit it by hand.
