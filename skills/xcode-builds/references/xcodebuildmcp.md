# The xcodebuildmcp CLI

Drives builds, tests, simulators, log capture and UI automation. Available two ways — as an MCP
server a project registers in `.mcp.json`, and as a plain executable.

## Do not learn its tool list from this file

The vendor ships its own agent skill, and it is the authority on what the tools are called:

```bash
xcodebuildmcp init --skill cli     # or --skill mcp when using the MCP server
xcodebuildmcp init --print         # read it without installing
```

That skill is versioned with the binary. Anything written here about workflow names or arguments
would be a copy that goes stale on the next release — 2.7 added `coverage`, `debugging`,
`swift-package` and `xcode-ide` workflows that an earlier copy did not mention, and a copy gives no
sign of being out of date. Ask the CLI instead:

```bash
xcodebuildmcp --help
xcodebuildmcp tools
xcodebuildmcp <workflow> <tool> --help
```

What follows is only the part the vendor's skill does not cover: what it costs to run unconfigured.

## Configure it before the first build, or pay for a second cache

Left unconfigured, xcodebuildmcp builds into a private store under
`~/Library/Developer/XcodeBuildMCP/workspaces/<project>-<hash>/`. Nothing else reads that store, so
the first build is cold and every build after it warms a cache Xcode, `scripts/build.sh` and
`scripts/test.sh` will never touch.

Measured on one SDK checkout: **3.53 GB** accumulated there before anyone noticed, and zero bytes
after `derivedDataPath` was bound to Xcode's own folder.

```bash
xcodebuildmcp purge          # what the private store currently holds
scripts/setup-tooling.sh     # bind derivedDataPath to Xcode's folder for this checkout
```

The binding cannot be committed: the folder is named from a hash of the checkout's absolute path, so
it differs per machine and per clone. That is why it is generated per checkout rather than shipped.

This is the same defect as `-derivedDataPath` on a routine `xcodebuild` — see the trap table in the
skill body. It is worth calling out separately only because the tool opts into it silently, where
`xcodebuild` at least requires you to type the flag.

## Registering the MCP server

A project registers it in `.mcp.json`. **A project-scoped server is inert until approved** — Claude
Code prompts once per project, and until someone answers, the file is present and the tools are not
loaded. A configured-but-unapproved server looks exactly like a working one from the repo.

Check with `/mcp`, not by reading `.mcp.json`.

Two silent failures live here, and both present as "the tools are just not there":

- **Not approved.** Answer the prompt, or the file does nothing.
- **Not on PATH.** `.mcp.json` takes no comments and gets no error surface, so a bare
  `"command": "xcodebuildmcp"` that the launch environment cannot resolve simply never starts. If
  `/mcp` shows it failed, substitute the output of `command -v xcodebuildmcp`.

## Exit criteria

- The tool list came from `--help`, `tools`, or the vendor's own skill — not from memory.
- `derivedDataPath` is bound for this checkout before the first build.
- If the MCP server is being used, `/mcp` shows it connected.
