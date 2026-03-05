import XCTest

@testable import HMStatus

final class RepoStatusTests: XCTestCase {
  let fixedDate = Date(timeIntervalSince1970: 1_700_000_000)

  // MARK: - Boolean state properties

  func testSyncedStatus() {
    let status = RepoStatus(ahead: 0, behind: 0, dirty: false, error: nil, checkedAt: fixedDate)
    XCTAssertTrue(status.isSynced)
    XCTAssertFalse(status.isAhead)
    XCTAssertFalse(status.isBehind)
    XCTAssertFalse(status.isDiverged)
    XCTAssertFalse(status.hasError)
  }

  func testAheadOnly() {
    let status = RepoStatus(ahead: 3, behind: 0, dirty: false, error: nil, checkedAt: fixedDate)
    XCTAssertFalse(status.isSynced)
    XCTAssertTrue(status.isAhead)
    XCTAssertFalse(status.isBehind)
    XCTAssertFalse(status.isDiverged)
  }

  func testBehindOnly() {
    let status = RepoStatus(ahead: 0, behind: 5, dirty: false, error: nil, checkedAt: fixedDate)
    XCTAssertFalse(status.isSynced)
    XCTAssertFalse(status.isAhead)
    XCTAssertTrue(status.isBehind)
    XCTAssertFalse(status.isDiverged)
  }

  func testDiverged() {
    let status = RepoStatus(ahead: 2, behind: 3, dirty: false, error: nil, checkedAt: fixedDate)
    XCTAssertFalse(status.isSynced)
    XCTAssertTrue(status.isAhead)
    XCTAssertTrue(status.isBehind)
    XCTAssertTrue(status.isDiverged)
  }

  func testErrorState() {
    let status = RepoStatus.error("jj not found", at: fixedDate)
    XCTAssertTrue(status.hasError)
    XCTAssertFalse(status.isSynced)
    XCTAssertFalse(status.isAhead)
    XCTAssertFalse(status.isBehind)
    XCTAssertFalse(status.isDiverged)
  }

  // MARK: - Menu bar text

  func testMenuBarTextSynced() {
    let status = RepoStatus.synced(at: fixedDate)
    XCTAssertEqual(status.menuBarText, "")
  }

  func testMenuBarTextAhead() {
    let status = RepoStatus(ahead: 2, behind: 0, dirty: false, error: nil, checkedAt: fixedDate)
    XCTAssertEqual(status.menuBarText, "\u{2191}2")
  }

  func testMenuBarTextBehind() {
    let status = RepoStatus(ahead: 0, behind: 7, dirty: false, error: nil, checkedAt: fixedDate)
    XCTAssertEqual(status.menuBarText, "\u{2193}7")
  }

  func testMenuBarTextDiverged() {
    let status = RepoStatus(ahead: 2, behind: 3, dirty: false, error: nil, checkedAt: fixedDate)
    XCTAssertEqual(status.menuBarText, "\u{2191}2\u{2193}3")
  }

  func testMenuBarTextError() {
    let status = RepoStatus.error("oops", at: fixedDate)
    XCTAssertEqual(status.menuBarText, "!")
  }

  func testMenuBarTextLargeNumbers() {
    let status = RepoStatus(
      ahead: 42, behind: 100, dirty: false, error: nil, checkedAt: fixedDate)
    XCTAssertEqual(status.menuBarText, "\u{2191}42\u{2193}100")
  }

  // MARK: - Menu bar label (text + dirty dot)

  func testMenuBarLabelSyncedClean() {
    let status = RepoStatus.synced(dirty: false, at: fixedDate)
    XCTAssertEqual(status.menuBarLabel, "\u{2713}")
  }

  func testMenuBarLabelSyncedDirty() {
    let status = RepoStatus.synced(dirty: true, at: fixedDate)
    XCTAssertEqual(status.menuBarLabel, "\u{25CF}")
  }

  func testMenuBarLabelAheadDirty() {
    let status = RepoStatus(ahead: 2, behind: 0, dirty: true, error: nil, checkedAt: fixedDate)
    XCTAssertEqual(status.menuBarLabel, "\u{2191}2\u{25CF}")
  }

  func testMenuBarLabelErrorNoDot() {
    let status = RepoStatus(
      ahead: 0, behind: 0, dirty: true, error: "err", checkedAt: fixedDate)
    XCTAssertEqual(status.menuBarLabel, "!")
  }

  // MARK: - Status description

  func testStatusDescriptionSynced() {
    let status = RepoStatus.synced(at: fixedDate)
    XCTAssertTrue(status.statusDescription.contains("In sync with trunk"))
    XCTAssertTrue(status.statusDescription.contains("Working copy is clean"))
  }

  func testStatusDescriptionAhead() {
    let status = RepoStatus(ahead: 1, behind: 0, dirty: false, error: nil, checkedAt: fixedDate)
    XCTAssertTrue(status.statusDescription.contains("1 commit ahead of trunk"))
  }

  func testStatusDescriptionAheadPlural() {
    let status = RepoStatus(ahead: 5, behind: 0, dirty: false, error: nil, checkedAt: fixedDate)
    XCTAssertTrue(status.statusDescription.contains("5 commits ahead of trunk"))
  }

  func testStatusDescriptionBehind() {
    let status = RepoStatus(ahead: 0, behind: 1, dirty: false, error: nil, checkedAt: fixedDate)
    XCTAssertTrue(status.statusDescription.contains("1 commit behind trunk"))
  }

  func testStatusDescriptionBehindPlural() {
    let status = RepoStatus(ahead: 0, behind: 3, dirty: false, error: nil, checkedAt: fixedDate)
    XCTAssertTrue(status.statusDescription.contains("3 commits behind trunk"))
  }

  func testStatusDescriptionDiverged() {
    let status = RepoStatus(ahead: 2, behind: 3, dirty: false, error: nil, checkedAt: fixedDate)
    XCTAssertTrue(status.statusDescription.contains("2 commits ahead of trunk"))
    XCTAssertTrue(status.statusDescription.contains("3 commits behind trunk"))
  }

  func testStatusDescriptionDirty() {
    let status = RepoStatus(ahead: 0, behind: 0, dirty: true, error: nil, checkedAt: fixedDate)
    XCTAssertTrue(status.statusDescription.contains("Working copy has changes"))
  }

  func testStatusDescriptionError() {
    let status = RepoStatus.error("jj not found", at: fixedDate)
    XCTAssertTrue(status.statusDescription.contains("Error: jj not found"))
  }

  // MARK: - Convenience initializers

  func testSyncedConvenience() {
    let status = RepoStatus.synced(dirty: true, at: fixedDate)
    XCTAssertEqual(status.ahead, 0)
    XCTAssertEqual(status.behind, 0)
    XCTAssertTrue(status.dirty)
    XCTAssertNil(status.error)
  }

  func testErrorConvenience() {
    let status = RepoStatus.error("boom", at: fixedDate)
    XCTAssertEqual(status.ahead, 0)
    XCTAssertEqual(status.behind, 0)
    XCTAssertFalse(status.dirty)
    XCTAssertEqual(status.error, "boom")
  }
}
