---
name: lint
description: "Run code formatting (SwiftFormat) and linting (SwiftLint) on the entire project."
user-invocable: true
allowed-tools:
  - Bash
---

Run code formatting (SwiftFormat) and linting (SwiftLint) on the entire project.

Step 1 -- Format:
```bash
swiftformat . 2>&1
```

Step 2 -- Lint with auto-fix:
```bash
swiftlint --fix --quiet 2>&1 || true
```

Step 3 -- Lint report:
```bash
swiftlint --quiet 2>&1
```

After running:
1. Report any SwiftFormat changes made (files modified).
2. Report any SwiftLint warnings or errors that could not be auto-fixed.
3. If everything is clean, confirm it.
