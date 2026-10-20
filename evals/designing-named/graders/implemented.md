---
type: llm
---
By the end of the run, annual_savings_percent in pricing.py rounds to the nearest percent instead of
truncating, so $10/month against $100/year gives 17. Any rounding method counts: round(), Decimal,
or adding 0.5 before truncating.
