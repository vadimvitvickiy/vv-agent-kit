# Apple's Xcode MCP

Apple's MCP server connects through `xcrun mcpbridge` and builds inside Xcode. See
[Apple's setup guide](https://developer.apple.com/documentation/xcode/giving-external-agents-access-to-xcode)
for registration and workspace access.

## Choose a runner

| Runner | Use it for |
|-|-|
| Apple's Xcode MCP | Xcode's live workspace, SwiftUI previews, issue diagnostics, and repeated local validation when its active selections match the task. |
| XcodeBuildMCP (now MobileBuildMCP) | Explicit project and simulator profiles, reusable test products, or scripted simulator automation such as inspecting the accessibility tree or recording video. |
| Project scripts | CI and project-specific verification that needs stable logs, result bundle paths, or test-gate integration. |

Xcode 27 added direct simulator control to Apple's MCP. MobileBuildMCP can also proxy Apple's
tools, and a proxied Apple build still uses Apple's build path.
[Xcode 27 release notes](https://developer.apple.com/documentation/xcode-release-notes/xcode-27-release-notes)

The [cache setup guide](xcodebuildmcp.md) uses XcodeBuildMCP names through v2.7.0. From v2.7.1,
check `mobilebuildmcp` and `.mobilebuildmcp/config.yaml` for the corresponding settings.
[MobileBuildMCP v2.7.1](https://github.com/getsentry/MobileBuildMCP/releases/tag/v2.7.1)

## Local iteration

- Pick one runner per worktree for the edit–build–test loop. Switching between Apple's MCP and
  the CLI can trigger extra work even when they share DerivedData.
- Target the intended checkout by workspace identifier or absolute path when the tool supports
  it. Check the active scheme and run destination before building and the active test plan before
  testing. If those selections are shared with another session, use the project scripts when you
  cannot verify they will stay correct during the run.
- Use `BuildProject` for compile checks. For focused tests, use `GetTestList` to obtain identifiers
  for `RunSomeTests`. Check the returned scheme, test plan, and results for the requested tests.
  An empty response, zero executed tests, or only skipped tests leaves verification incomplete.
- Use the response's full log or summary path when diagnostics are truncated. If MCP is unavailable
  or the run cannot be verified, use the project's scripts. A returned build or test failure is
  evidence to investigate.

## Compare runners on your project

Use the same checkout, Xcode build version, scheme, configuration, concrete destination, and test
filter. Verify DerivedData from the logs if comparing cache reuse. Compare several warm no-op or
incremental builds and repeated focused tests with the actual project scripts. Run each runner in a
block and record the first run after switching separately. Compare end-to-end wall time, tests
executed, and the amount of output the agent receives.

On one macOS workspace the MCP saved seconds per repeated build and focused test, while full app
test times were similar. Timing and switching costs depend on the project and toolchain.
[SwiftLee's benchmark](https://www.avanderlee.com/ai-development/xcode-mcp-vs-xcodebuild/)
