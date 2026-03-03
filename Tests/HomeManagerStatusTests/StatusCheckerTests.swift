import Foundation
import Testing

@testable import HomeManagerStatus

// MARK: - Mock Command Runner

/// A mock JujutsuCommandRunner that returns predefined responses based on arguments.
struct MockJujutsuCommandRunner: JujutsuCommandRunner, Sendable {
  let responses: @Sendable ([String]) -> Result<String, Error>

  init(responses: @escaping @Sendable ([String]) -> Result<String, Error>) {
    self.responses = responses
  }

  /// Create a mock that returns fixed outputs for ahead, behind, and dirty queries.
  static func fixed(ahead: String, behind: String, dirty: String) -> MockJujutsuCommandRunner {
    MockJujutsuCommandRunner { args in
      // Identify which command is being run by inspecting the revset argument
      if let revsetIndex = args.firstIndex(of: "-r"),
        revsetIndex + 1 < args.count
      {
        let revset = args[revsetIndex + 1]
        if revset.contains("::@ ~ ::trunk()") {
          return .success(ahead)
        } else if revset.contains("::trunk() ~ ::@") {
          return .success(behind)
        } else if revset == "@" {
          return .success(dirty)
        }
      }
      return .failure(MockError.unexpectedArgs(args))
    }
  }

  /// Create a mock that always fails.
  static func failing(error: String) -> MockJujutsuCommandRunner {
    MockJujutsuCommandRunner { _ in
      .failure(MockError.simulated(error))
    }
  }

  func run(args: [String], repoPath: String) async throws -> String {
    switch responses(args) {
    case .success(let output):
      return output
    case .failure(let error):
      throw error
    }
  }

  enum MockError: LocalizedError {
    case unexpectedArgs([String])
    case simulated(String)

    var errorDescription: String? {
      switch self {
      case .unexpectedArgs(let args):
        return "Unexpected args: \(args)"
      case .simulated(let msg):
        return msg
      }
    }
  }
}

// MARK: - StatusChecker Tests

@Suite(.serialized)
struct StatusCheckerTests {
  @Test @MainActor func refreshSynced() async {
    let runner = MockJujutsuCommandRunner.fixed(ahead: "", behind: "", dirty: "clean")
    let checker = StatusChecker(repoPath: "/tmp/test", refreshInterval: 300, runner: runner)

    await checker.refresh()

    #expect(checker.status.isSynced)
    #expect(!checker.status.dirty)
    #expect(checker.status.error == nil)
  }

  @Test @MainActor func refreshAhead() async {
    let runner = MockJujutsuCommandRunner.fixed(
      ahead: "abc123\ndef456\n", behind: "", dirty: "clean")
    let checker = StatusChecker(repoPath: "/tmp/test", refreshInterval: 300, runner: runner)

    await checker.refresh()

    #expect(checker.status.ahead == 2)
    #expect(checker.status.behind == 0)
    #expect(checker.status.isAhead)
  }

  @Test @MainActor func refreshBehind() async {
    let runner = MockJujutsuCommandRunner.fixed(
      ahead: "", behind: "abc123\ndef456\nghi789\n", dirty: "clean")
    let checker = StatusChecker(repoPath: "/tmp/test", refreshInterval: 300, runner: runner)

    await checker.refresh()

    #expect(checker.status.ahead == 0)
    #expect(checker.status.behind == 3)
    #expect(checker.status.isBehind)
  }

  @Test @MainActor func refreshDiverged() async {
    let runner = MockJujutsuCommandRunner.fixed(
      ahead: "abc123\n", behind: "def456\nghi789\n", dirty: "dirty")
    let checker = StatusChecker(repoPath: "/tmp/test", refreshInterval: 300, runner: runner)

    await checker.refresh()

    #expect(checker.status.ahead == 1)
    #expect(checker.status.behind == 2)
    #expect(checker.status.dirty)
    #expect(checker.status.isDiverged)
  }

  @Test @MainActor func refreshDirtyOnly() async {
    let runner = MockJujutsuCommandRunner.fixed(ahead: "", behind: "", dirty: "dirty")
    let checker = StatusChecker(repoPath: "/tmp/test", refreshInterval: 300, runner: runner)

    await checker.refresh()

    #expect(checker.status.isSynced)
    #expect(checker.status.dirty)
  }

  @Test @MainActor func refreshWithError() async {
    let runner = MockJujutsuCommandRunner.failing(error: "jj: command not found")
    let checker = StatusChecker(repoPath: "/tmp/test", refreshInterval: 300, runner: runner)

    await checker.refresh()

    #expect(checker.status.hasError)
    #expect(checker.status.error?.contains("jj: command not found") == true)
  }

  @Test @MainActor func initialStatusIsNotYetChecked() {
    let runner = MockJujutsuCommandRunner.fixed(ahead: "", behind: "", dirty: "clean")
    let checker = StatusChecker(repoPath: "/tmp/test", refreshInterval: 300, runner: runner)

    #expect(checker.status.hasError)
    #expect(checker.status.error == "Not yet checked")
  }

  @Test @MainActor func repoPathIsPreserved() {
    let runner = MockJujutsuCommandRunner.fixed(ahead: "", behind: "", dirty: "clean")
    let checker = StatusChecker(
      repoPath: "/home/user/.config/home-manager", refreshInterval: 300, runner: runner)

    #expect(checker.repoPath == "/home/user/.config/home-manager")
  }

  @Test @MainActor func refreshUpdatesStatus() async {
    let runner = MockJujutsuCommandRunner.fixed(
      ahead: "", behind: "abc123\n", dirty: "clean")
    let checker = StatusChecker(repoPath: "/tmp/test", refreshInterval: 300, runner: runner)

    // Initial state is error (not yet checked)
    #expect(checker.status.hasError)

    // After refresh, should be behind
    await checker.refresh()
    #expect(checker.status.isBehind)
    #expect(checker.status.behind == 1)
  }
}
