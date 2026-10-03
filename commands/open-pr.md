---
description: Write a pull request title and description for the current branch, push it, and open the creation page in the browser.
disable-model-invocation: true
---

Describe the current branch as a pull request, and open the creation page for the human to submit.

**REQUIRED BACKGROUND:** `vvkit:committing-changes` — the title rules and the four parts of a
description live there and are not restated here.

This needs the `gh` CLI, authenticated. If it is missing, write the title and description into the
reply instead and say why.

## 1. Gather

```bash
git status --short
git log <base>..HEAD --format='%s%n%b'
git diff <base>...HEAD
```

The base is the repository's default branch unless the human named another. When the current branch
*is* the base, stop: a pull request needs a branch of its own.

Read the changed files where the diff alone does not explain the change. Use the conversation too:
it holds the why, which the diff never does.

## 2. Uncommitted work

Typing this command is the request to commit what belongs in the pull request. Commit staged
changes, following the repository's convention. When there are unstaged changes as well, list them
and ask whether they belong; do not sweep them in.

## 3. Write it

A title and a description as `vvkit:committing-changes` sets them out. Where the repository has a
pull request template — `.github/pull_request_template.md` — fill that template in and keep its
headings.

The "what was verified" part names commands actually run in this session and what they printed. If
nothing was run, say that rather than writing a testing section from the diff.

## 4. Push and open

```bash
git push -u origin HEAD
gh pr create --web --title "<title>" --body "<body>"
```

`--web` opens the creation page filled in and submits nothing. The human reads it and presses the
button; do not create the pull request directly.

A push that is rejected means the remote moved. Say so and stop — never force it from here.
