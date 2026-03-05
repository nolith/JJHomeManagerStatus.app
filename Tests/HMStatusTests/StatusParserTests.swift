import Foundation
import XCTest

@testable import HMStatus

final class StatusParserTests: XCTestCase {
  let fixedDate = Date(timeIntervalSince1970: 1_700_000_000)

  // MARK: - parseCommitCount

  func testParseCommitCountEmpty() {
    XCTAssertEqual(StatusParser.parseCommitCount(from: ""), 0)
  }

  func testParseCommitCountWhitespaceOnly() {
    XCTAssertEqual(StatusParser.parseCommitCount(from: "   \n  \n  "), 0)
  }

  func testParseCommitCountSingleCommit() {
    XCTAssertEqual(StatusParser.parseCommitCount(from: "abc123\n"), 1)
  }

  func testParseCommitCountSingleCommitNoNewline() {
    XCTAssertEqual(StatusParser.parseCommitCount(from: "abc123"), 1)
  }

  func testParseCommitCountMultipleCommits() {
    let output = "abc123\ndef456\nghi789\n"
    XCTAssertEqual(StatusParser.parseCommitCount(from: output), 3)
  }

  func testParseCommitCountMultipleCommitsNoTrailingNewline() {
    let output = "abc123\ndef456\nghi789"
    XCTAssertEqual(StatusParser.parseCommitCount(from: output), 3)
  }

  func testParseCommitCountWithLeadingTrailingWhitespace() {
    let output = "\n  abc123\ndef456  \n"
    // After trimming: "abc123\ndef456" => 2 lines
    XCTAssertEqual(StatusParser.parseCommitCount(from: output), 2)
  }

  // MARK: - parseDirtyStatus

  func testParseDirtyStatusClean() throws {
    let result = try StatusParser.parseDirtyStatus(from: "clean")
    XCTAssertFalse(result)
  }

  func testParseDirtyStatusDirty() throws {
    let result = try StatusParser.parseDirtyStatus(from: "dirty")
    XCTAssertTrue(result)
  }

  func testParseDirtyStatusCleanWithWhitespace() throws {
    let result = try StatusParser.parseDirtyStatus(from: "  clean  \n")
    XCTAssertFalse(result)
  }

  func testParseDirtyStatusDirtyWithWhitespace() throws {
    let result = try StatusParser.parseDirtyStatus(from: "\ndirty\n")
    XCTAssertTrue(result)
  }

  func testParseDirtyStatusUnexpectedOutput() {
    XCTAssertThrowsError(try StatusParser.parseDirtyStatus(from: "unknown"))
  }

  func testParseDirtyStatusEmptyOutput() {
    XCTAssertThrowsError(try StatusParser.parseDirtyStatus(from: ""))
  }

  // MARK: - parse (combined)

  func testParseInSync() {
    let status = StatusParser.parse(
      aheadOutput: "",
      behindOutput: "",
      dirtyOutput: "clean",
      at: fixedDate
    )
    XCTAssertEqual(status.ahead, 0)
    XCTAssertEqual(status.behind, 0)
    XCTAssertFalse(status.dirty)
    XCTAssertNil(status.error)
    XCTAssertTrue(status.isSynced)
  }

  func testParseAheadOnly() {
    let status = StatusParser.parse(
      aheadOutput: "abc123\ndef456\n",
      behindOutput: "",
      dirtyOutput: "clean",
      at: fixedDate
    )
    XCTAssertEqual(status.ahead, 2)
    XCTAssertEqual(status.behind, 0)
    XCTAssertFalse(status.dirty)
    XCTAssertTrue(status.isAhead)
  }

  func testParseBehindOnly() {
    let status = StatusParser.parse(
      aheadOutput: "",
      behindOutput: "abc123\ndef456\nghi789\n",
      dirtyOutput: "clean",
      at: fixedDate
    )
    XCTAssertEqual(status.ahead, 0)
    XCTAssertEqual(status.behind, 3)
    XCTAssertTrue(status.isBehind)
  }

  func testParseDiverged() {
    let status = StatusParser.parse(
      aheadOutput: "abc123\n",
      behindOutput: "def456\nghi789\n",
      dirtyOutput: "dirty",
      at: fixedDate
    )
    XCTAssertEqual(status.ahead, 1)
    XCTAssertEqual(status.behind, 2)
    XCTAssertTrue(status.dirty)
    XCTAssertTrue(status.isDiverged)
  }

  func testParseDirtyWorkingCopy() {
    let status = StatusParser.parse(
      aheadOutput: "",
      behindOutput: "",
      dirtyOutput: "dirty",
      at: fixedDate
    )
    XCTAssertTrue(status.isSynced)
    XCTAssertTrue(status.dirty)
  }

  func testParseInvalidDirtyOutputReturnsError() {
    let status = StatusParser.parse(
      aheadOutput: "abc123\n",
      behindOutput: "",
      dirtyOutput: "garbage",
      at: fixedDate
    )
    XCTAssertTrue(status.hasError)
    XCTAssertTrue(status.error?.contains("Unexpected dirty status output") == true)
  }

  func testParsePreservesDate() {
    let status = StatusParser.parse(
      aheadOutput: "",
      behindOutput: "",
      dirtyOutput: "clean",
      at: fixedDate
    )
    XCTAssertEqual(status.checkedAt, fixedDate)
  }
}
