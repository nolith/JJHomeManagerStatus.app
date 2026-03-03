import SwiftUI
import Testing

@testable import HomeManagerStatus

struct RepoStatusTests {
  let fixedDate = Date(timeIntervalSince1970: 1_700_000_000)

  // MARK: - Boolean state properties

  @Test func syncedStatus() {
    let status = RepoStatus(ahead: 0, behind: 0, dirty: false, error: nil, checkedAt: fixedDate)
    #expect(status.isSynced)
    #expect(!status.isAhead)
    #expect(!status.isBehind)
    #expect(!status.isDiverged)
    #expect(!status.hasError)
  }

  @Test func aheadOnly() {
    let status = RepoStatus(ahead: 3, behind: 0, dirty: false, error: nil, checkedAt: fixedDate)
    #expect(!status.isSynced)
    #expect(status.isAhead)
    #expect(!status.isBehind)
    #expect(!status.isDiverged)
  }

  @Test func behindOnly() {
    let status = RepoStatus(ahead: 0, behind: 5, dirty: false, error: nil, checkedAt: fixedDate)
    #expect(!status.isSynced)
    #expect(!status.isAhead)
    #expect(status.isBehind)
    #expect(!status.isDiverged)
  }

  @Test func diverged() {
    let status = RepoStatus(ahead: 2, behind: 3, dirty: false, error: nil, checkedAt: fixedDate)
    #expect(!status.isSynced)
    #expect(status.isAhead)
    #expect(status.isBehind)
    #expect(status.isDiverged)
  }

  @Test func errorState() {
    let status = RepoStatus.error("jj not found", at: fixedDate)
    #expect(status.hasError)
    #expect(!status.isSynced)
    #expect(!status.isAhead)
    #expect(!status.isBehind)
    #expect(!status.isDiverged)
  }

  // MARK: - Menu bar icon

  @Test func menuBarIconSynced() {
    let status = RepoStatus.synced(at: fixedDate)
    #expect(status.menuBarIcon == "checkmark.circle.fill")
  }

  @Test func menuBarIconAhead() {
    let status = RepoStatus(ahead: 1, behind: 0, dirty: false, error: nil, checkedAt: fixedDate)
    #expect(status.menuBarIcon == "arrow.up.circle.fill")
  }

  @Test func menuBarIconBehind() {
    let status = RepoStatus(ahead: 0, behind: 1, dirty: false, error: nil, checkedAt: fixedDate)
    #expect(status.menuBarIcon == "arrow.down.circle.fill")
  }

  @Test func menuBarIconDiverged() {
    let status = RepoStatus(ahead: 2, behind: 3, dirty: false, error: nil, checkedAt: fixedDate)
    #expect(status.menuBarIcon == "arrow.up.arrow.down.circle.fill")
  }

  @Test func menuBarIconError() {
    let status = RepoStatus.error("oops", at: fixedDate)
    #expect(status.menuBarIcon == "exclamationmark.triangle.fill")
  }

  // MARK: - Menu bar color

  @Test func menuBarColorSynced() {
    let status = RepoStatus.synced(at: fixedDate)
    #expect(status.menuBarColor == .green)
  }

  @Test func menuBarColorAhead() {
    let status = RepoStatus(ahead: 1, behind: 0, dirty: false, error: nil, checkedAt: fixedDate)
    #expect(status.menuBarColor == .blue)
  }

  @Test func menuBarColorBehind() {
    let status = RepoStatus(ahead: 0, behind: 1, dirty: false, error: nil, checkedAt: fixedDate)
    #expect(status.menuBarColor == .orange)
  }

  @Test func menuBarColorDiverged() {
    let status = RepoStatus(ahead: 1, behind: 1, dirty: false, error: nil, checkedAt: fixedDate)
    #expect(status.menuBarColor == .yellow)
  }

  @Test func menuBarColorError() {
    let status = RepoStatus.error("oops", at: fixedDate)
    #expect(status.menuBarColor == .red)
  }

  // MARK: - Menu bar text

  @Test func menuBarTextSynced() {
    let status = RepoStatus.synced(at: fixedDate)
    #expect(status.menuBarText == "")
  }

  @Test func menuBarTextAhead() {
    let status = RepoStatus(ahead: 2, behind: 0, dirty: false, error: nil, checkedAt: fixedDate)
    #expect(status.menuBarText == "\u{2191}2")
  }

  @Test func menuBarTextBehind() {
    let status = RepoStatus(ahead: 0, behind: 7, dirty: false, error: nil, checkedAt: fixedDate)
    #expect(status.menuBarText == "\u{2193}7")
  }

  @Test func menuBarTextDiverged() {
    let status = RepoStatus(ahead: 2, behind: 3, dirty: false, error: nil, checkedAt: fixedDate)
    #expect(status.menuBarText == "\u{2191}2\u{2193}3")
  }

  @Test func menuBarTextError() {
    let status = RepoStatus.error("oops", at: fixedDate)
    #expect(status.menuBarText == "!")
  }

  @Test func menuBarTextLargeNumbers() {
    let status = RepoStatus(
      ahead: 42, behind: 100, dirty: false, error: nil, checkedAt: fixedDate)
    #expect(status.menuBarText == "\u{2191}42\u{2193}100")
  }

  // MARK: - Menu bar label (text + dirty dot)

  @Test func menuBarLabelSyncedClean() {
    let status = RepoStatus.synced(dirty: false, at: fixedDate)
    #expect(status.menuBarLabel == "")
  }

  @Test func menuBarLabelSyncedDirty() {
    let status = RepoStatus.synced(dirty: true, at: fixedDate)
    #expect(status.menuBarLabel == "\u{25CF}")
  }

  @Test func menuBarLabelAheadDirty() {
    let status = RepoStatus(ahead: 2, behind: 0, dirty: true, error: nil, checkedAt: fixedDate)
    #expect(status.menuBarLabel == "\u{2191}2\u{25CF}")
  }

  @Test func menuBarLabelErrorNoDot() {
    let status = RepoStatus(
      ahead: 0, behind: 0, dirty: true, error: "err", checkedAt: fixedDate)
    // Error state should not show dirty dot
    #expect(status.menuBarLabel == "!")
  }

  // MARK: - Status description

  @Test func statusDescriptionSynced() {
    let status = RepoStatus.synced(at: fixedDate)
    #expect(status.statusDescription.contains("In sync with trunk"))
    #expect(status.statusDescription.contains("Working copy is clean"))
  }

  @Test func statusDescriptionAhead() {
    let status = RepoStatus(ahead: 1, behind: 0, dirty: false, error: nil, checkedAt: fixedDate)
    #expect(status.statusDescription.contains("1 commit ahead of trunk"))
  }

  @Test func statusDescriptionAheadPlural() {
    let status = RepoStatus(ahead: 5, behind: 0, dirty: false, error: nil, checkedAt: fixedDate)
    #expect(status.statusDescription.contains("5 commits ahead of trunk"))
  }

  @Test func statusDescriptionBehind() {
    let status = RepoStatus(ahead: 0, behind: 1, dirty: false, error: nil, checkedAt: fixedDate)
    #expect(status.statusDescription.contains("1 commit behind trunk"))
  }

  @Test func statusDescriptionBehindPlural() {
    let status = RepoStatus(ahead: 0, behind: 3, dirty: false, error: nil, checkedAt: fixedDate)
    #expect(status.statusDescription.contains("3 commits behind trunk"))
  }

  @Test func statusDescriptionDiverged() {
    let status = RepoStatus(ahead: 2, behind: 3, dirty: false, error: nil, checkedAt: fixedDate)
    #expect(status.statusDescription.contains("2 commits ahead of trunk"))
    #expect(status.statusDescription.contains("3 commits behind trunk"))
  }

  @Test func statusDescriptionDirty() {
    let status = RepoStatus(ahead: 0, behind: 0, dirty: true, error: nil, checkedAt: fixedDate)
    #expect(status.statusDescription.contains("Working copy has changes"))
  }

  @Test func statusDescriptionError() {
    let status = RepoStatus.error("jj not found", at: fixedDate)
    #expect(status.statusDescription.contains("Error: jj not found"))
  }

  // MARK: - Convenience initializers

  @Test func syncedConvenience() {
    let status = RepoStatus.synced(dirty: true, at: fixedDate)
    #expect(status.ahead == 0)
    #expect(status.behind == 0)
    #expect(status.dirty)
    #expect(status.error == nil)
  }

  @Test func errorConvenience() {
    let status = RepoStatus.error("boom", at: fixedDate)
    #expect(status.ahead == 0)
    #expect(status.behind == 0)
    #expect(!status.dirty)
    #expect(status.error == "boom")
  }
}
