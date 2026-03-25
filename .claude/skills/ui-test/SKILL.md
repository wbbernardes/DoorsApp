---
name: ui-test
description: "Run UI tests for the DoorsApp scheme on iPhone 17 Pro simulator."
user-invocable: true
allowed-tools:
  - Bash
---

Run UI tests for the DoorsApp scheme on iPhone 17 Pro simulator.

Run this command and summarize the results:

```bash
xcodebuild -project DoorsApp.xcodeproj \
  -scheme DoorsApp \
  -destination "platform=iOS Simulator,name=iPhone 17 Pro" \
  -only-testing:DoorsAppUITests \
  test 2>&1 | xcbeautify
```

After the run:
1. Report total UI tests run, passed, and failed.
2. For each failure, show: test name, failure reason, and any screenshots if available.
3. If all pass, confirm with a short summary.
