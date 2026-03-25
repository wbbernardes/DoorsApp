---
paths:
  - "**/*.swift"
---

# Swift Code Style Rules

- Run SwiftFormat and SwiftLint before every commit.
- **No force unwraps** (`!`) — use `guard let`, `if let`, or nil coalescing.
- **No force try** (`try!`) — use `do/catch` or `try?` with sensible defaults.
- Prefer `async/await` over completion handlers.
- Use Combine only where it's already the established pattern in a module.
- Prefer value types (`struct`) over reference types (`class`) unless identity semantics are needed.
- Use `@Model` (SwiftData) for persistence models. `@Model` classes must be `final`.
- Keep views small: extract subviews and view models when a view exceeds ~100 lines.
- **iOS 17+ only** — use modern APIs freely (`@Observable`, SwiftData, etc.).

## Observation

- Always `@Observable final class` for ViewModels, never `ObservableObject`.
- **NEVER use** `@ObservedObject`, `@StateObject`, or `@Published`.
- Add `@MainActor` when the ViewModel mutates UI state from async contexts.

## Concurrency

- Always use `async/await` for asynchronous operations.
- Never use Combine for new code.
- Use `Task { }` to bridge sync -> async in ViewModel action methods.
- Use structured concurrency (`TaskGroup`, `async let`) for parallel work.
