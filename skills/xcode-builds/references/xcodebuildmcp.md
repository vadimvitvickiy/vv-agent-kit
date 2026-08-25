# XcodeBuildMCP CLI

Drive builds, tests, simulators, logs and UI automation through the `xcodebuildmcp` executable
instead of raw `xcodebuild`, `xcrun` or `simctl`.

## 1. Confirm the CLI exists

```bash
xcodebuildmcp --help
```

If missing:

```bash
brew tap getsentry/xcodebuildmcp && brew install xcodebuildmcp
# or
npm install -g xcodebuildmcp@latest
```

Re-check after installing.

## 2. Discover, don't memorize

The tool list changes between versions. Ask the CLI rather than working from a remembered list:

```bash
xcodebuildmcp --help
xcodebuildmcp tools
xcodebuildmcp <workflow> --help
xcodebuildmcp <workflow> <tool> --help
```

This is the general pattern for any unfamiliar CLI: discover capability from the tool itself, so the
instructions cannot go stale against it.

## 3. Keep execution minimal

- Choose the smallest command sequence that satisfies the request.
- Prefer a direct workflow command over a manual multi-step chain.
- For "run it on the simulator", prefer the combined `build-and-run`.
- Do not chain `build` and then `build-and-run` — the second does the first.

## Capabilities

Simulator and device build/test/run · debugging and log capture · UI automation · project discovery
and scaffolding · session defaults.

## Exit criteria

- CLI presence verified, or install steps given.
- Commands discovered via `--help` / `tools`, not assumed.
- Session defaults checked before the first build, run, or test.
