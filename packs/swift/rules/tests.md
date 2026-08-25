---
paths:
  - "**/*.swift"
---

# Tests

New or changed behaviour ships with a test **in the same change** — including every bug fix, with
the reproducing test written first and watched to fail.

A test that passes against broken code is worse than no test. Break the line it claims to cover and
confirm it fails.

Never widen access to reach something. If the behaviour is unreachable through the real seam, that
is a design finding to report.

Full rule, exemptions and the acceptance filter: `vvkit:writing-tests`.
Swift Testing conventions and the `#expect` silent-pass trap: `vvkit:swift-testing`.
