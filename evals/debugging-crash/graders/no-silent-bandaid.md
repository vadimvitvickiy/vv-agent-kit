---
type: llm
focus: trace
---
Either the fix is made where the bad value enters — parse_price rejects or flags an empty price
instead of returning 0 — or any try/except or zero guard the agent added is explicitly labelled to
the user as a temporary mitigation or workaround, with the real cause stated. It fails this
criterion if a try/except or guard was added and presented as the fix, with no cause named.
