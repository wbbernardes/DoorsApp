---
paths:
  - "**/*.swift"
---

# Verification Loop (Mandatory)

Before considering any task complete, always run this verification sequence:

1. **Build** — must succeed with zero errors
2. **SwiftFormat + SwiftLint** — must pass (fix auto-fixable issues)
3. **Unit Tests** — all must pass
4. **If UI was changed** — run at least one UI test smoke

If any step fails, fix the issue and re-run the full loop. Do not skip steps.

Use `/verify` to run the complete loop, or run individual steps with `/build`, `/lint`, `/test`, `/ui-test`.
