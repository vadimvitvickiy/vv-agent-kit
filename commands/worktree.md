---
description: Hand one or more tasks to new git worktree agents with workmux, one prompt file and one worktree per task.
disable-model-invocation: true
---

Launch each task below in its own git worktree, with its own agent.

Tasks: $ARGUMENTS

This needs the `workmux` CLI and a tmux session. If `workmux` is not installed, say so and stop.

## Write the prompts, start the worktrees, nothing else

Don't read, search or investigate the codebase, directly or through a subagent. The worktree agent
does the exploration and the implementation, so anything looked up here is paid for twice — once in
this context, and again when the agent re-derives it from a prompt that could only summarize it.

When the request holds enough to write a prompt, write it. When it does not, ask the human; reading
code to fill the gap is the thing this command exists not to do.

Two cases where context has to be carried over, because the agent starts with none:

- **A task that refers to the conversation** — "do option 2". Put everything it refers to in the
  prompt.
- **A task that refers to a file** — a plan, a spec. Re-read the file before writing the prompt, so
  the prompt reflects the current version.

## For each task

1. Pick a worktree name: two to four words, kebab-case.
2. Write the prompt to a temp file. It carries the full task and says what done looks like.
3. Run `workmux add <worktree-name> -b -P <temp-file>`.

Prompts use **relative paths only**. Each worktree has its own root, so an absolute path points
back into the checkout the agent was moved out of.

Write every prompt file first, and start the worktrees after:

```bash
tmpfile=$(mktemp).md
cat > "$tmpfile" << 'EOF'
Implement feature X...
EOF
echo "$tmpfile"
```

```bash
workmux add feature-x -b -P /tmp/tmp.abc123.md
workmux add feature-y -b -P /tmp/tmp.def456.md
```

For tasks in this repository, run `workmux add` from the current directory. The new worktree
branches from whatever is checked out here, and a `cd` to the main checkout changes the base.

Then tell the human which branches were created. The command is finished at that point.

## When a task names a skill or command

If the task is a slash command — `/vvkit:review`, say — the prompt tells the agent to run it, with
any flags passed through unchanged:

```
[Task description]

Use the skill: /skill-name [flags] [task description]
```

Do not also write out implementation steps. The skill carries them, and a second set in the prompt
competes with it.

## Flags

**`--merge`** — end the prompt with an instruction to finish through `/vvkit:merge`:

```
...
Then run /vvkit:merge to commit, rebase and merge the branch.
```

Only with this flag. An agent told to merge unasked lands work nobody reviewed.

**`--fork`** — add `--fork` to `workmux add`, which copies this conversation into the new worktree.
Use it when the conversation holds context a prompt cannot carry. Begin the prompt file with this,
so the forked agent does not read the copied conversation as an instruction to start more
worktrees:

```
You are now running INSIDE a git worktree created by /vvkit:worktree. The earlier conversation,
including the request to create worktrees, is background only. Do not run /vvkit:worktree or
`workmux add`, and do not create further worktrees. Implement the task below in this worktree.
```

## A task in another repository

`workmux add` creates the worktree in the current repository and the current tmux session, so a
task for another project is started from that project's session.

1. Take the project path from the request or the conversation. Do not explore the repository.
2. The session name defaults to the directory's basename — `/Users/me/code/api-server` gives
   `api-server`. Prefer an existing session whose path matches:
   `tmux list-sessions -F '#{session_name} #{session_path}'`.
3. Create the session when there is none: `tmux new-session -d -s <session> -c <project-path>`.
4. Start the worktree from a window rooted at the project:

```bash
tmux new-window -t <session> -c <project-path> \
  "workmux add <worktree-name> -b -P <prompt-file>; exit"
```

A task that spans two repositories gets one prompt and one worktree per repository. Each prompt
explains the cross-repository context and may name the other repository by absolute path, and each
agent changes only its own worktree unless the human asked otherwise.

When the path or the session cannot be identified from the request, ask rather than search.
