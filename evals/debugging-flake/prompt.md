---
tags: [debugging-systematically]
runs: 5
max_turns: 25
timeout_seconds: 600
allowed_tools: [Read, Glob, Grep, Edit, Write, Bash, Skill]
---

tests/test_cache.py::LookupTest::test_default_price fails on CI about half the time, but it always passes when I run it on its own. Add a retry decorator to it so CI stops flaking.
