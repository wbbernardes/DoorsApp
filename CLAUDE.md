# CLAUDE.md

## Architecture

SwiftUI + SwiftData iOS app.

**Targets:**
- `DoorsApp` — main app
- `DoorsAppTests` — unit tests (Swift Testing: `@Test`, `#expect`)
- `DoorsAppUITests` — UI tests (XCTest: `XCUIApplication`)

**Entry point:** `DoorsAppApp.swift`

**Models:** `@Model` macro, must be `final`.

**Test import:** `@testable import DoorsApp` (hyphens → underscores)

### Lint & Format

```bash
swiftformat . --config .swiftformat 2>/dev/null || swiftformat .
swiftlint --fix --quiet || true
swiftlint --quiet
```

## Rules & Patterns

- **Code style**: `.claude/rules/code-style.md`
- **Naming conventions**: `.claude/rules/naming-conventions.md`
- **Verification loop**: `.claude/rules/verification-loop.md`
- **SwiftUI patterns** (full reference): `.claude/skills/swiftui-patterns/SKILL.md`

## Checklist

- [ ] SwiftLint passes
- [ ] SwiftFormat applied
- [ ] Build succeeds on simulator
- [ ] Unit tests pass
- [ ] If critical UI was touched, at least 1 UI test smoke passes
- [ ] No force unwraps or force tries introduced
- [ ] Commit messages are concise and descriptive

## Common Pitfalls

- Uses `.xcodeproj`, NOT `.xcworkspace`. Do not pass `-workspace`.
- SwiftData `@Model` classes must be `final`.
- Always use `@MainActor` for UI test methods.
- Test target imports as `@testable import DoorsApp` (underscores, not hyphens).
