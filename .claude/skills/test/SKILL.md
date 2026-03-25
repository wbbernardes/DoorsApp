---
name: test
description: "Run all unit tests for the DoorsApp scheme on iPhone 17 Pro simulator."
user-invocable: true
allowed-tools:
  - Bash
---

Run all unit tests for the DoorsApp scheme on iPhone 17 Pro simulator.

Run this command and summarize the results:

```bash
xcodebuild -project DoorsApp.xcodeproj \
  -scheme DoorsApp \
  -destination "platform=iOS Simulator,name=iPhone 17 Pro" \
  test 2>&1 | xcbeautify
```

After the run:
1. Report total tests run, passed, and failed.
2. For each failure, show: test name, file, line number, and failure reason.
3. If all tests pass, confirm with a short summary.
