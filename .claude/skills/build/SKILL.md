---
name: build
description: "Build the project in Debug configuration for iPhone 17 Pro simulator."
user-invocable: true
allowed-tools:
  - Bash
---

Build the project in Debug configuration for iPhone 17 Pro simulator.

Run this command and report the result:

```bash
xcodebuild -project DoorsApp.xcodeproj \
  -scheme DoorsApp \
  -destination "platform=iOS Simulator,name=iPhone 17 Pro" \
  -configuration Debug \
  build 2>&1 | xcbeautify
```

If the build fails:
1. Show the exact error(s) with file path and line number.
2. Suggest a fix for each error.
3. Ask if I want you to apply the fixes.
