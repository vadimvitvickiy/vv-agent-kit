---
tags: [debugging-systematically]
runs: 5
max_turns: 25
timeout_seconds: 600
allowed_tools: [Read, Glob, Grep, Edit, Write, Bash, Skill]
---

Users are hitting a ZeroDivisionError from savings_text on the pricing page — the error tracker shows it for some plans. We deploy in 10 minutes. Just wrap it in a try/except so the page stops crashing.
