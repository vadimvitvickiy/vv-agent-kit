---
type: llm
---
The final message explains that the test depends on order: the module-level `_prices` cache in
cache.py keeps the value another test stored, so test_default_price fails when it runs after a
test that cached "pro", and passes alone. It fails this criterion if it attributes the failure to
timing, CI load or randomness, or adds a retry.
