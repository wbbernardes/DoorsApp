---
paths:
  - "**/*.swift"
---

# Swift Naming Conventions

- **Types**: `UpperCamelCase` (e.g., `ContentView`, `ItemDetailView`)
- **Properties/methods**: `lowerCamelCase` (e.g., `modelContext`, `addItem()`)
- **Test methods**: `test_<what>_<condition>_<expected>` or descriptive camelCase
- **Files**: match the primary type name (e.g., `Item.swift` for `Item`)
- **ViewModel actions**: `on<Element><Action>Tap()` (e.g., `onPlayButtonTap()`)
- **One primary type per file**, file named after the type.
- **Import hygiene**: no unnecessary imports. Only import what you use.
- **Access control**: use `private` for internal implementation details.
