---
type: regex
pattern: 'retry|sleep|flaky|rerun'
flags: i
match: not_contains
target: {source: file, path: tests/test_cache.py}
---
No retry, sleep or rerun was added to the test.
