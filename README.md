# DoorsApp

iOS mobile challenge for Vingcard / Livvi Smart Access Control platform.

**Seniority:** Senior iOS Developer

---

## Features

| Feature | Status | Notes |
|---|---|---|
| Sign Up / Sign In | Implemented | Token stored in Keychain, session persisted across launches |
| Doors List | Implemented | Paginated (20/page), infinite scroll, debounced search |
| Door Events | Implemented | Human-readable parsed events + raw BLE frame view |
| BLE Frame Parser | Implemented | Full binary protocol coverage (13+ event types) |
| Feature Flags | Implemented | Firebase Remote Config — alternate door detail UI |
| Door Permissions | Skipped | Managing door access grants via API — cut for time, architecture supports adding it |
| Encrypted Requests (plus) | Skipped | ECDH + HKDF + AES-GCM over BLE — bonus challenge, deserves full dedicated attention |

---

## Architecture

```
DoorsApp (Xcode target)
│
├── Firebase (Analytics + Crashlytics + Remote Config) — via SPM
│
└── DoorsPackages/ (local multi-target SPM package)
    ├── CoreNetwork      ← URLSession client, Keychain, Endpoint enum
    ├── BLEKit           ← BLE frame parser, simulator, event types
    ├── DomainKit        ← Models, Repository protocols, Use Cases
    ├── DesignSystemKit  ← Shared UI components
    ├── AuthFeature      ← Sign Up / Sign In screens + ViewModel
    ├── DoorsFeature     ← Doors list + search
    └── EventsFeature    ← Door detail, events list, raw BLE view
```

### Layer breakdown

```
View (SwiftUI)
    │  @State / @Binding
    ▼
ViewModel (@Observable @MainActor)
    │  calls
    ▼
Use Cases (business logic, no I/O)
    │  depends on
    ▼
Repository Protocols (DomainKit — interface only)
    │  injected at runtime
    ▼
Repository Implementations (concrete, per feature)
    │  calls
    ▼
APIClient / KeychainService (CoreNetwork)
```

**Key decisions:**

- **No third-party networking.** `URLSession` + a generic `async throws` `request<T: Decodable>` function is all that was needed.
- **`@Observable` (iOS 17+), never `ObservableObject`.** Modern macro-based observation — no `@Published`, no `@StateObject`.
- **Protocol-based repositories.** Every ViewModel depends on a protocol, not a concrete type. This makes unit testing trivial — swap in a mock, no network needed.
- **Local SPM package** for enforced module boundaries. Features cannot reach into each other's internals.
- **Keychain for tokens.** Never UserDefaults. Token is read fresh before each request via the `APIClient`.

---

## BLE Protocol

The API returns BLE frames as Base64-encoded byte arrays. Each frame follows this layout:

```
Bytes 0–3  │ Timestamp — UInt32 little-endian (seconds since 2026-01-01T00:00:00Z)
Byte  4    │ logCode
             ├── upper nibble (bits 7-4): payload length in bytes
             └── lower nibble (bits 3-0): event type identifier
Bytes 5..N │ Payload — little-endian, variable length (0–12 bytes)
```

`ParseBLEFrameUseCase` covers all logCode variants:

| logCode range | Event family | Payload |
|---|---|---|
| `0x00`–`0x09` | Setup, door open/close, access events | 0 bytes |
| `0x10`–`0x13` | Status, battery | 1 byte |
| `0x20`–`0x21` | EEPROM errors | 2 bytes (UInt16 LE) |
| `0x40`–`0x47` | Configuration, reset, error | 4 bytes (UInt32 LE) |
| `0x50`–`0x51` | Unlock / Unlock denied | 5 bytes (permission mode + permissionID) |
| `0xC0` | Schedule init | 12 bytes (userID + start + end timestamps) |

The `GET /doors/events/simulate?debug=true` endpoint was used during development to cross-validate the parser against the API's own expected output.

---

## Prerequisites

- Xcode 26 (Beta) or later
- iOS 26 Simulator (iPhone 17 Pro recommended)
- Swift 6.2 toolchain (bundled with Xcode 26)
- `swiftlint` and `swiftformat` installed via Homebrew (optional, for lint/format)

```bash
brew install swiftlint swiftformat
```

---

## Build & Run

1. Clone the repository.
2. Open `DoorsApp.xcodeproj` in Xcode (not `.xcworkspace` — there isn't one).
3. Select the `DoorsApp` scheme and an **iPhone 17 Pro** simulator.
4. Press **Cmd+R** to build and run.

The app resolves `DoorsPackages` as a local Swift Package automatically. No extra steps needed.

> **Firebase:** A `GoogleService-Info.plist` is included in the repo. Remote Config is active. The `newDoorDetailUI` flag controls whether the door detail view uses a segmented picker or tabs.

---

## Running Tests

### Unit tests (Swift Testing)

```bash
xcodebuild test \
  -project DoorsApp.xcodeproj \
  -scheme DoorsApp \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro'
```

Or in Xcode: **Cmd+U** with the `DoorsApp` scheme selected.

Test suites:

| Suite | What it covers |
|---|---|
| `AuthViewModelTests` | Email/password validation, sign in/up flows, error states |
| `DoorsListViewModelTests` | Pagination state, debounced search, unauthorized handling |
| `EventsViewModelTests` | Event loading, raw frame toggle, BLE simulation |
| `ParseBLEFrameUseCaseTests` | All logCode variants, epoch offset, payload extraction |
| `UseCaseTests` | FetchDoors, SearchDoors, FetchEvents use cases |
| `PaginatedResponseTests` | Response model decoding and `hasMore` logic |
| `NetworkErrorTests` | Error enum cases and localized descriptions |

### UI tests (XCTest)

```bash
xcodebuild test \
  -project DoorsApp.xcodeproj \
  -scheme DoorsApp \
  -testPlan DoorsApp \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  -only-testing DoorsAppUITests
```

UI tests cover the Sign Up password validation flow (4 scenarios).

---

## AI Usage

Claude Code (claude-sonnet-4-6) was used throughout this project as a pairing tool.

**What AI generated or scaffolded:**
- Initial boilerplate for SPM `Package.swift` and target structure
- Mock implementations for unit tests (`MockDoorsRepository`, `MockURLProtocol`, etc.)
- SwiftLint / SwiftFormat configuration files
- Repetitive ViewModel state patterns (loading, error, pagination flags)

**What was reviewed, adjusted, or written manually:**
- BLE frame parsing logic — reviewed byte-by-byte against the API's debug output to confirm correctness
- Authentication flow and Keychain integration — inspected and adjusted error handling
- Feature flag service wiring with Firebase Remote Config
- Architecture decisions (module boundaries, use case granularity, repository protocol design)
- All test assertions — verified each `#expect` against actual API responses

AI output was always reviewed before accepting. No generated code was blindly committed.
