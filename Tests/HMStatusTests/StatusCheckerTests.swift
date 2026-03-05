import Foundation
import XCTest

@testable import HMStatus

// MARK: - Mock Command Runner

/// A mock JujutsuCommandRunner that returns predefined responses based on arguments.
struct MockJujutsuCommandRunner: JujutsuCommandRunner {
  let responses: ([String]) -> Result<String, Error>

  init(responses: @escaping ([String]) -> Result<String, Error>) {
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

@MainActor
final class StatusCheckerTests: XCTestCase {

  func testRefreshSynced() async {
    let runner = MockJujutsuCommandRunner.fixed(ahead: "", behind: "", dirty: "clean")
    let checker = StatusChecker(repoPath: "/tmp/test", refreshInterval: 300, runner: runner)

    await checker.refresh()

    XCTAssertTrue(checker.status.isSynced)
    XCTAssertFalse(checker.status.dirty)
    XCTAssertNil(checker.status.error)
  }

  func testRefreshAhead() async {
    let runner = MockJujutsuCommandRunner.fixed(
      ahead: "abc123\ndef456\n", behind: "", dirty: "clean")
    let checker = StatusChecker(repoPath: "/tmp/test", refreshInterval: 300, runner: runner)

    await checker.refresh()

    XCTAssertEqual(checker.status.ahead, 2)
    XCTAssertEqual(checker.status.behind, 0)
    XCTAssertTrue(checker.status.isAhead)
  }

  func testRefreshBehind() async {
    let runner = MockJujutsuCommandRunner.fixed(
      ahead: "", behind: "abc123\ndef456\nghi789\n", dirty: "clean")
    let checker = StatusChecker(repoPath: "/tmp/test", refreshInterval: 300, runner: runner)

    await checker.refresh()

    XCTAssertEqual(checker.status.ahead, 0)
    XCTAssertEqual(checker.status.behind, 3)
    XCTAssertTrue(checker.status.isBehind)
  }

  func testRefreshDiverged() async {
    let runner = MockJujutsuCommandRunner.fixed(
      ahead: "abc123\n", behind: "def456\nghi789\n", dirty: "dirty")
    let checker = StatusChecker(repoPath: "/tmp/test", refreshInterval: 300, runner: runner)

    await checker.refresh()

    XCTAssertEqual(checker.status.ahead, 1)
    XCTAssertEqual(checker.status.behind, 2)
    XCTAssertTrue(checker.status.dirty)
    XCTAssertTrue(checker.status.isDiverged)
  }

  func testRefreshDirtyOnly() async {
    let runner = MockJujutsuCommandRunner.fixed(ahead: "", behind: "", dirty: "dirty")
    let checker = StatusChecker(repoPath: "/tmp/test", refreshInterval: 300, runner: runner)

    await checker.refresh()

    XCTAssertTrue(checker.status.isSynced)
    XCTAssertTrue(checker.status.dirty)
  }

  func testRefreshWithError() async {
    let runner = MockJujutsuCommandRunner.failing(error: "jj: command not found")
    let checker = StatusChecker(repoPath: "/tmp/test", refreshInterval: 300, runner: runner)

    await checker.refresh()

    XCTAssertTrue(checker.status.hasError)
    XCTAssertTrue(checker.status.error?.contains("jj: command not found") == true)
  }

  func testInitialStatusIsNotYetChecked() {
    let runner = MockJujutsuCommandRunner.fixed(ahead: "", behind: "", dirty: "clean")
    let checker = StatusChecker(repoPath: "/tmp/test", refreshInterval: 300, runner: runner)

    XCTAssertTrue(checker.status.hasError)
    XCTAssertEqual(checker.status.error, "Not yet checked")
  }

  func testRepoPathIsPreserved() {
    let runner = MockJujutsuCommandRunner.fixed(ahead: "", behind: "", dirty: "clean")
    let checker = StatusChecker(
      repoPath: "/home/user/.config/home-manager", refreshInterval: 300, runner: runner)

    XCTAssertEqual(checker.repoPath, "/home/user/.config/home-manager")
  }

  func testRefreshUpdatesStatus() async {
    let runner = MockJujutsuCommandRunner.fixed(
      ahead: "", behind: "abc123\n", dirty: "clean")
    let checker = StatusChecker(repoPath: "/tmp/test", refreshInterval: 300, runner: runner)

    // Initial state is error (not yet checked)
    XCTAssertTrue(checker.status.hasError)

    // After refresh, should be behind
    await checker.refresh()
    XCTAssertTrue(checker.status.isBehind)
    XCTAssertEqual(checker.status.behind, 1)
  }
}
