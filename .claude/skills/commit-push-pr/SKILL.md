---
name: commit-push-pr
description: "Prepare and push a clean commit."
user-invocable: true
allowed-tools:
  - Bash
---

Prepare and push a clean commit.

Before committing, run the full verification loop (build + lint + test). If anything fails, fix it first.

## Step 1 -- Verify (do not skip)

Run `/verify` steps (build, lint, test). All must pass before proceeding.

## Step 2 -- Stage & Commit

```bash
git status
git diff --stat
```

Review the changes, then:
1. Stage all relevant files (do NOT stage `.DS_Store`, `xcuserdata/`, or build artifacts).
2. Write a concise commit message that describes the "why", not just the "what".
3. Commit.

```bash
git add -A
git reset HEAD -- '*.DS_Store' '**/xcuserdata/**' '**/DerivedData/**' 2>/dev/null || true
git commit -m "<your message here>"
```

## Step 3 -- Push

```bash
git push -u origin HEAD
```
