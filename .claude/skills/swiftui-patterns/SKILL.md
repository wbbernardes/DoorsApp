---
name: swiftui-patterns
description: SwiftUI view creation patterns, layout constants, localization, property wrappers, ViewModel conventions, and concurrency rules for iOS 17+. Use when creating, modifying, reviewing, or simplifying any SwiftUI view or ViewModel.
user-invocable: false
---

# SwiftUI View Creation Patterns (iOS 17+)

This is the authoritative guide for building SwiftUI views in this project. All code that creates, modifies, simplifies, or reviews UI MUST follow these patterns.

This project targets **iOS 17+ exclusively**. Use modern APIs freely: `@Observable`, SwiftData, async/await.

---

## File Structure Order

Every SwiftUI view file follows this exact order:
1. File header comment
2. Minimal imports (`SwiftUI` only unless more are needed)
3. View struct
4. Extension with `Layout` / `Constants` / `Style` enum
5. `#Preview` block at the end

Example skeleton:

```swift
//
//  MyView.swift
//

import SwiftUI

struct MyView: View {
    @State var viewModel = MyViewModel()

    var body: some View {
        VStack(spacing: Layout.verticalSpacing) {
            Text(viewModel.title)
                .padding(.horizontal, Layout.horizontalPadding)
        }
    }
}

extension MyView {
    typealias Strings = MyFeatureStrings

    enum Layout {
        static let horizontalPadding: CGFloat = 16
        static let verticalSpacing: CGFloat = 12
    }
}

#Preview {
    MyView()
}
```

---

## No Magic Numbers

All literal values (CGFloat, Int, String identifiers) must live in a `Layout`, `Constants`, or `Style` enum declared inside an `extension` on the view. **Never inline raw numbers in the body.**

### Pattern A — `Layout` enum (preferred for small/medium views)

```swift
extension MyView {
    typealias Strings = MyViewStrings

    enum Layout {
        static let horizontalPadding: CGFloat = 16
        static let imageSize: CGFloat = 32
        static let cornerRadius: CGFloat = 8
        static let titleLineLimit: Int = 1
    }
}
```

### Pattern B — `Constants` with `Dimensions` + `Appearance` (for views with many values)

```swift
extension MyView {
    enum Constants {
        static let sectionTitle: String = "Latest episodes"

        enum Dimensions {
            static let horizontalPadding: CGFloat = 16
            static let artworkSize: CGFloat = 96
        }

        enum Appearance {
            static let titleColor = Color.primary
            static let backgroundColor = Color(.systemBackground)
        }
    }
}
```

---

## Property Wrappers

| Wrapper | When to use |
|---------|------------|
| `@State var viewModel` | ViewModel owned by the view (most common) |
| `@State private var` | Local view state |
| `@Environment(\.key)` | System values: `dismiss`, `horizontalSizeClass`, `colorScheme` |
| `@Binding` | Two-way state from parent |
| `@ViewBuilder` | Generic content parameter |
| `let` | Read-only props on child components |

### BANNED Property Wrappers

**NEVER use** these:
- `@ObservedObject` → use `let` or `@Binding`
- `@StateObject` → use `@State var viewModel` with `@Observable` class
- `@Published` → use plain properties on `@Observable` class
- `ObservableObject` → use `@Observable` macro

---

## ViewModel Conventions

```swift
@Observable
final class MyViewModel {

    // MARK: - Dependencies
    private let service: MyService

    // MARK: - Local UI State
    private(set) var items: [Item] = []
    var showingAlert = false

    // MARK: - Computed Properties
    var hasContent: Bool { !items.isEmpty }

    // MARK: - Initialization
    init(service: MyService = .shared) {
        self.service = service
    }

    // MARK: - Actions
    func onPlayButtonTap() {
        Task { await service.play() }
    }
}
```

Rules:
- Always `@Observable final class`, never `ObservableObject`.
- Add `@MainActor` when the ViewModel mutates UI state from async contexts.
- Name actions as `on<Element><Action>Tap()`.
- Wrap async calls in `Task { }` inside synchronous action methods.
- Use `MARK:` sections: Dependencies, Local UI State, Computed Properties, Initialization, Actions.
- Default parameter values in `init` for testability.

---

## Reusable Child Components

```swift
struct MyButton: View {
    let label: LocalizedStringKey
    let action: () -> Void
    let isDisabled: Bool

    init(label: LocalizedStringKey, isDisabled: Bool = false, action: @escaping () -> Void) {
        self.label = label
        self.isDisabled = isDisabled
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            Text(label)
                .padding(.horizontal, Layout.horizontalPadding)
        }
        .disabled(isDisabled)
        .opacity(isDisabled ? Layout.disabledOpacity : Layout.enabledOpacity)
        .accessibilityLabel(label)
    }
}

extension MyButton {
    enum Layout {
        static let horizontalPadding: CGFloat = 16
        static let iconSize: CGFloat = 24
        static let disabledOpacity: Double = 0.4
        static let enabledOpacity: Double = 1.0
    }
}

#Preview {
    MyButton(label: "Play") { }
}
```

---

## UI Consistency Rules

- **Colors**: Use semantic colors via `Color` extensions, not inline `Color(.systemX)`.
- **Dynamic Type**: Cap with `.dynamicTypeSize(...DynamicTypeSize.xLarge)`.
- **Disabled state**: Always both `.disabled(condition)` + `.opacity(condition ? 0.4 : 1.0)`.
- **Buttons**: Use `.buttonStyle(.plain)` or `.buttonStyle(.borderless)` for custom buttons.
- **Accessibility**: `.accessibilityLabel()` on every interactive element.
- **Transitions**: Use `.transition(.opacity.combined(with: .scale(...)))` for smooth animations.

---

## Folder Organization

```
Feature/
  FeatureView.swift
  FeatureViewModel.swift
  FeatureStrings.swift
  FeatureStyle.swift          // optional
  SubComponentView.swift
```

---

## Concurrency Rules

- Always use `async/await` for asynchronous operations.
- Never use Combine for new code.
- Use `Task { }` to bridge sync → async in ViewModel action methods.
- Use `@MainActor` on ViewModels that mutate UI state from async contexts.
- Use structured concurrency (`TaskGroup`, `async let`) for parallel work.
