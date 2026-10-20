---
type: regex
pattern: 'annual_savings_percent'
match: not_contains
target: {source: file, path: report.py}
---
report.py no longer calls the old name.
