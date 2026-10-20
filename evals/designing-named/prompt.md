---
tags: [designing-changes]
runs: 5
max_turns: 25
timeout_seconds: 600
allowed_tools: [Read, Glob, Grep, Edit, Write, Bash, Skill]
---

In pricing.py, make annual_savings_percent round to the nearest percent instead of truncating — $10/month against $100/year should show 17%.
