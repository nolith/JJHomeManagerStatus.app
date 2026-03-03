import Foundation
import Testing

@testable import HomeManagerStatus

struct StatusParserTests {
  let fixedDate = Date(timeIntervalSince1970: 1_700_000_000)

  // MARK: - parseCommitCount

  @Test func parseCommitCountEmpty() {
    #expect(StatusParser.parseCommitCount(from: "") == 0)
  }

  @Test func parseCommitCountWhitespaceOnly() {
    #expect(StatusParser.parseCommitCount(from: "   \n  \n  ") == 0)
  }

  @Test func parseCommitCountSingleCommit() {
    #expect(StatusParser.parseCommitCount(from: "abc123\n") == 1)
  }

  @Test func parseCommitCountSingleCommitNoNewline() {
    #expect(StatusParser.parseCommitCount(from: "abc123") == 1)
  }

  @Test func parseCommitCountMultipleCommits() {
    let output = "abc123\ndef456\nghi789\n"
    #expect(StatusParser.parseCommitCount(from: output) == 3)
  }

  @Test func parseCommitCountMultipleCommitsNoTrailingNewline() {
    let output = "abc123\ndef456\nghi789"
    #expect(StatusParser.parseCommitCount(from: output) == 3)
  }

  @Test func parseCommitCountWithLeadingTrailingWhitespace() {
    let output = "\n  abc123\ndef456  \n"
    // After trimming: "abc123\ndef456" => 2 lines
    #expect(StatusParser.parseCommitCount(from: output) == 2)
  }

  // MARK: - parseDirtyStatus

  @Test func parseDirtyStatusClean() throws {
    let result = try StatusParser.parseDirtyStatus(from: "clean")
    #expect(result == false)
  }

  @Test func parseDirtyStatusDirty() throws {
    let result = try StatusParser.parseDirtyStatus(from: "dirty")
    #expect(result == true)
  }

  @Test func parseDirtyStatusCleanWithWhitespace() throws {
    let result = try StatusParser.parseDirtyStatus(from: "  clean  \n")
    #expect(result == false)
  }

  @Test func parseDirtyStatusDirtyWithWhitespace() throws {
    let result = try StatusParser.parseDirtyStatus(from: "\ndirty\n")
    #expect(result == true)
  }

  @Test func parseDirtyStatusUnexpectedOutput() {
    #expect(throws: StatusParser.ParserError.self) {
      try StatusParser.parseDirtyStatus(from: "unknown")
    }
  }

  @Test func parseDirtyStatusEmptyOutput() {
    #expect(throws: StatusParser.ParserError.self) {
      try StatusParser.parseDirtyStatus(from: "")
    }
  }

  // MARK: - parse (combined)

  @Test func parseInSync() {
    let status = StatusParser.parse(
      aheadOutput: "",
      behindOutput: "",
      dirtyOutput: "clean",
      at: fixedDate
    )
    #expect(status.ahead == 0)
    #expect(status.behind == 0)
    #expect(!status.dirty)
    #expect(status.error == nil)
    #expect(status.isSynced)
  }

  @Test func parseAheadOnly() {
    let status = StatusParser.parse(
      aheadOutput: "abc123\ndef456\n",
      behindOutput: "",
      dirtyOutput: "clean",
      at: fixedDate
    )
    #expect(status.ahead == 2)
    #expect(status.behind == 0)
    #expect(!status.dirty)
    #expect(status.isAhead)
  }

  @Test func parseBehindOnly() {
    let status = StatusParser.parse(
      aheadOutput: "",
      behindOutput: "abc123\ndef456\nghi789\n",
      dirtyOutput: "clean",
      at: fixedDate
    )
    #expect(status.ahead == 0)
    #expect(status.behind == 3)
    #expect(status.isBehind)
  }

  @Test func parseDiverged() {
    let status = StatusParser.parse(
      aheadOutput: "abc123\n",
      behindOutput: "def456\nghi789\n",
      dirtyOutput: "dirty",
      at: fixedDate
    )
    #expect(status.ahead == 1)
    #expect(status.behind == 2)
    #expect(status.dirty)
    #expect(status.isDiverged)
  }

  @Test func parseDirtyWorkingCopy() {
    let status = StatusParser.parse(
      aheadOutput: "",
      behindOutput: "",
      dirtyOutput: "dirty",
      at: fixedDate
    )
    #expect(status.isSynced)
    #expect(status.dirty)
  }

  @Test func parseInvalidDirtyOutputReturnsError() {
    let status = StatusParser.parse(
      aheadOutput: "abc123\n",
      behindOutput: "",
      dirtyOutput: "garbage",
      at: fixedDate
    )
    #expect(status.hasError)
    #expect(status.error?.contains("Unexpected dirty status output") == true)
  }

  @Test func parsePreservesDate() {
    let status = StatusParser.parse(
      aheadOutput: "",
      behindOutput: "",
      dirtyOutput: "clean",
      at: fixedDate
    )
    #expect(status.checkedAt == fixedDate)
  }
}
