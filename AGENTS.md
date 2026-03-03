# Agent Guidelines for HomeManagerStatus

This document provides guidelines for AI coding agents working on this codebase.

## Project Overview

HomeManagerStatus is a macOS menu bar app written in Swift that displays the Jujutsu (jj) status of `~/.config/home-manager`. It's packaged with Nix and includes a home-manager module for launchd integration.

## Build Commands

### Swift (development)

```bash
# Build (debug)
swift build

# Build (release)
swift build -c release

# Run the app directly (for testing)
swift run
```

### Nix (production)

```bash
# Build the package
nix build

# Enter development shell (provides swift-format)
nix develop

# Format all files (Nix, Shell, Swift)
nix fmt

# Check flake validity
nix flake check
```

## Test Commands

```bash
# Run all tests
swift test

# Run a single test file
swift test --filter HomeManagerStatusTests.StatusParserTests

# Run a single test method
swift test --filter HomeManagerStatusTests.StatusParserTests/testParseCommitCountEmpty

# Run tests with verbose output
swift test --verbose
```

## Code Style

### Formatting

This project uses `swift-format` for Swift code formatting, configured via treefmt-nix. Always run `nix fmt` before committing.

Key formatting rules:
- 2-space indentation
- Line length: 100 characters (soft limit)
- Trailing commas in multi-line collections

### Imports

Order imports alphabetically. Standard library and system frameworks first:

```swift
import Foundation
import SwiftUI
import XCTest

@testable import HomeManagerStatus
```

### Naming Conventions

| Type | Convention | Example |
|------|------------|---------|
| Types (struct, class, enum, protocol) | PascalCase | `RepoStatus`, `StatusParser` |
| Functions and methods | camelCase | `parseCommitCount`, `startPolling` |
| Variables and properties | camelCase | `refreshInterval`, `repoPath` |
| Constants | camelCase | `fixedDate` |
| Enum cases | camelCase | `unexpectedDirtyOutput` |

### Types and Protocols

- Prefer `struct` over `class` unless reference semantics are required
- Use `@MainActor` for UI-bound types (e.g., `StatusChecker`)
- Define protocols for testability (e.g., `JujutsuCommandRunner`)
- Use `enum` with no cases for namespacing pure functions (e.g., `StatusParser`)

### Error Handling

- Define errors as nested enums conforming to `LocalizedError`
- Provide `errorDescription` for user-facing messages
- Use `Result` for mock/test code, `throws` for production code

```swift
enum ParserError: LocalizedError {
  case unexpectedDirtyOutput(String)

  var errorDescription: String? {
    switch self {
    case .unexpectedDirtyOutput(let output):
      return "Unexpected dirty status output: '\(output)'"
    }
  }
}
```

### Documentation

- Use `///` doc comments for public APIs
- Include parameter and return descriptions for non-trivial functions
- Use `// MARK: -` to organize code sections

```swift
/// Parse the output of `jj log` that lists commit short IDs (one per line)
/// and return the count of commits.
///
/// - Parameter output: Raw stdout from jj log command
/// - Returns: Number of commits listed
static func parseCommitCount(from output: String) -> Int { ... }
```

### Testing

- Test files mirror source files: `StatusParser.swift` -> `StatusParserTests.swift`
- Use descriptive test names: `testParseCommitCountEmpty`, `testRefreshWithError`
- Group related tests with `// MARK: -` comments
- Use fixed dates for deterministic tests: `let fixedDate = Date(timeIntervalSince1970: 1_700_000_000)`
- Create mock implementations of protocols for unit testing

### Async/Await

- Use `async/await` for asynchronous operations
- Use `withCheckedThrowingContinuation` to bridge callback-based APIs
- Mark test methods as `async` when testing async code
- Use `@MainActor` for classes that publish to SwiftUI

## Project Structure

```
.
├── Sources/HomeManagerStatus/
│   ├── HomeManagerStatusApp.swift   # App entry point, SwiftUI views
│   ├── StatusChecker.swift          # Orchestrates polling and state
│   ├── StatusParser.swift           # Pure parsing functions
│   ├── RepoStatus.swift             # Data model
│   └── JujutsuCommandRunner.swift   # Protocol + live implementation
├── Tests/HomeManagerStatusTests/
│   ├── StatusCheckerTests.swift
│   ├── StatusParserTests.swift
│   └── RepoStatusTests.swift
├── nix/
│   ├── package.nix                  # Nix derivation
│   └── modules/home-manager.nix     # home-manager module
├── Package.swift                    # Swift package manifest
├── Info.plist                       # macOS app bundle metadata
└── flake.nix                        # Nix flake
```

## Version Control

This project uses Jujutsu (jj). Key commands:

```bash
jj status              # Show working copy changes
jj diff --git          # Show diff in git format
jj describe -m "msg"   # Set commit message (don't use jj commit)
jj new                 # Create new change
```

Do NOT use interactive jj commands (`jj commit`, `jj split`) without `-m` flag.

## Nix Module

The home-manager module exposes:
- `programs.jj-home-manager-status.enable` (bool)
- `programs.jj-home-manager-status.package` (package)

When modifying the module, test with:
```bash
nix flake check
nix eval '.#homeManagerModules.default'
```

## Platform Requirements

- macOS 13.0+ (Ventura)
- Swift 5.9+
- Jujutsu (jj) in PATH
