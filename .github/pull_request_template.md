## What changes and why

<!-- The diff shows what. Explain why, and what you ruled out. -->

## Verified

```
./scripts/validate.sh                  # exit 0
./scripts/validate.sh tests/fixtures   # exit 1
claude plugin validate . --strict      # exit 0
```

- [ ] All three ran, and their output is what is pasted above
- [ ] Every claim added to a skill has a measured number or a named failure mode behind it
- [ ] Nothing repo-specific reached `skills/`, `agents/`, `commands/` or `hooks/`
- [ ] Any `description` added states triggering conditions and does not narrate a workflow
- [ ] If `validate.sh` changed, a fixture that the new rule rejects was added
- [ ] If a hook changed, it still exits 0 on unparseable and on empty stdin
