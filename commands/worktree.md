---
description: Hand one or more independent tasks to agents that each work in their own git worktree and branch.
disable-model-invocation: true
---

Launch each task below as its own agent, in its own git worktree, on its own branch.

Tasks: $ARGUMENTS

**REQUIRED BACKGROUND:** `vvkit:delegating-work` for the spawn-prompt contract and for accepting a
result, and `vvkit:choosing-subagent-models` — every launch names its model.

Use the harness's own worktree isolation: a subagent launched with `isolation: worktree`, in the
background. Where the harness has none, say so and stop. A `git worktree add` behind the harness's
back creates state it cannot see or clean up.

## Write the prompts, launch the agents, nothing else

Don't read, search or investigate the codebase, directly or through a research subagent. Each
worktree agent does its own exploration and implementation, so anything looked up here is paid for
twice — once in this context, and again when the agent re-derives it from a prompt that could only
summarize it.

When the request holds enough to write a prompt, write it. When it does not, ask the human; reading
code to fill the gap is the thing this command exists not to do.

## The tasks must be independent

This is the one place the kit runs writers side by side, and a worktree is what makes it safe to
edit: no agent sees another's files. It does nothing for the merge. Two tasks that change the same
code conflict when the second branch lands, after both were paid for.

If two tasks plainly touch the same area, say so before launching and offer to run them in
sequence. The human chose the split; they decide.

## Each prompt

An agent starts with none of this conversation. Its prompt carries:

- **The whole task**, and what done looks like.
- **Everything the task refers to.** "Do option 2" means writing option 2 out. A task that points at
  a plan or a spec: re-read the file first, so the prompt reflects the current version.
- **Relative paths only.** Each worktree has its own root, and an absolute path points back into the
  checkout the agent was moved out of.
- **How to finish**: run the project's tests, commit the work on the worktree's branch following
  `vvkit:committing-changes`, and report the branch name, what was verified with which command, and
  anything left undone. Not merge, and not push.
- **A slash command, when the task names one** — `/vvkit:review`, say — with its flags passed
  through unchanged, and no implementation steps beside it. The command carries them, and a second
  set in the prompt competes with it.

The commit is asked for here, on the human's behalf, because an uncommitted worktree cannot be
merged and is discarded with its directory.

Launch every agent in one message, so they run together.

## When the agents report

Tell the human which branches exist and what each agent says it verified. A report is a claim: read
the diff of each branch before calling it done — "Accepting a result" in `vvkit:delegating-work`.

Integration is a separate, explicit step. `/vvkit:merge <branch>` lands one branch; land them one at
a time, because each merge moves the base the next one rebases onto.

An agent that changed nothing leaves no worktree behind. One that failed leaves its worktree and
branch: report where they are rather than removing them.
