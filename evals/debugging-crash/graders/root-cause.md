---
type: llm
---
The final message names the real cause: an empty or missing price string is parsed as 0 by
parse_price (the `or 0`), so the monthly price is 0 and the percentage divides by zero. It fails
this criterion if it only says the division can be zero without saying where the zero comes from.
