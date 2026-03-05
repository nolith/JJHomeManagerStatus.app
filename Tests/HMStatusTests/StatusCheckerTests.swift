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

final class StatusCheckerTests: XCTestCase {

  func testCheckSynced() async {
    let runner = MockJujutsuCommandRunner.fixed(ahead: "", behind: "", dirty: "clean")
    let status = await StatusChecker.check(repoPath: "/tmp/test", runner: runner)

    XCTAssertTrue(status.isSynced)
    XCTAssertFalse(status.dirty)
    XCTAssertNil(status.error)
  }

  func testCheckAhead() async {
    let runner = MockJujutsuCommandRunner.fixed(
      ahead: "abc123\ndef456\n", behind: "", dirty: "clean")
    let status = await StatusChecker.check(repoPath: "/tmp/test", runner: runner)

    XCTAssertEqual(status.ahead, 2)
    XCTAssertEqual(status.behind, 0)
    XCTAssertTrue(status.isAhead)
  }

  func testCheckBehind() async {
    let runner = MockJujutsuCommandRunner.fixed(
      ahead: "", behind: "abc123\ndef456\nghi789\n", dirty: "clean")
    let status = await StatusChecker.check(repoPath: "/tmp/test", runner: runner)

    XCTAssertEqual(status.ahead, 0)
    XCTAssertEqual(status.behind, 3)
    XCTAssertTrue(status.isBehind)
  }

  func testCheckDiverged() async {
    let runner = MockJujutsuCommandRunner.fixed(
      ahead: "abc123\n", behind: "def456\nghi789\n", dirty: "dirty")
    let status = await StatusChecker.check(repoPath: "/tmp/test", runner: runner)

    XCTAssertEqual(status.ahead, 1)
    XCTAssertEqual(status.behind, 2)
    XCTAssertTrue(status.dirty)
    XCTAssertTrue(status.isDiverged)
  }

  func testCheckDirtyOnly() async {
    let runner = MockJujutsuCommandRunner.fixed(ahead: "", behind: "", dirty: "dirty")
    let status = await StatusChecker.check(repoPath: "/tmp/test", runner: runner)

    XCTAssertTrue(status.isSynced)
    XCTAssertTrue(status.dirty)
  }

  func testCheckWithError() async {
    let runner = MockJujutsuCommandRunner.failing(error: "jj: command not found")
    let status = await StatusChecker.check(repoPath: "/tmp/test", runner: runner)

    XCTAssertTrue(status.hasError)
    XCTAssertTrue(status.error?.contains("jj: command not found") == true)
  }
}
