---
name: verify
description: "Run the full verification loop. This is the \"Boris-style\" verify: build, lint, test -- all must pass."
user-invocable: true
allowed-tools:
  - Bash
---

Run the full verification loop. This is the "Boris-style" verify: build, lint, test -- all must pass.

Do NOT skip any step. If any step fails, stop and report before continuing.

## Step 1 -- Build

```bash
xcodebuild -project DoorsApp.xcodeproj \
  -scheme DoorsApp \
  -destination "platform=iOS Simulator,name=iPhone 17 Pro" \
  -configuration Debug \
  build 2>&1 | xcbeautify
```

If build fails -> stop and report errors.

## Step 2 -- Format & Lint

```bash
swiftformat . 2>&1
swiftlint --fix --quiet 2>&1 || true
swiftlint --quiet 2>&1
```

If lint errors remain -> report them.

## Step 3 -- Unit Tests

```bash
xcodebuild -project DoorsApp.xcodeproj \
  -scheme DoorsApp \
  -destination "platform=iOS Simulator,name=iPhone 17 Pro" \
  test 2>&1 | xcbeautify
```

If tests fail -> report failures with details.

## Final Report

Summarize:
- Build: PASS / FAIL
- Lint: PASS / FAIL (N warnings)
- Tests: PASS / FAIL (N passed, N failed)

If all green -> "Verification complete. Ready for PR."
If any red -> list what needs fixing.
