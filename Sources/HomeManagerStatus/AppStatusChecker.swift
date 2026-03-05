import Foundation
import HMStatus
import SwiftUI

/// Orchestrates periodic jj status checks and publishes results for the UI.
@MainActor
final class AppStatusChecker: ObservableObject {
  @Published private(set) var status: RepoStatus

  let repoPath: String
  let refreshInterval: TimeInterval
  private let runner: JujutsuCommandRunner
  private var timer: Timer?

  init(
    repoPath: String,
    refreshInterval: TimeInterval = 300,  // 5 minutes
    runner: JujutsuCommandRunner = LiveJujutsuCommandRunner()
  ) {
    self.repoPath = repoPath
    self.refreshInterval = refreshInterval
    self.runner = runner
    self.status = RepoStatus(
      ahead: 0, behind: 0, dirty: false,
      error: "Not yet checked",
      checkedAt: Date()
    )
  }

  /// Start periodic status checks.
  func startPolling() {
    // Run immediately
    Task { await refresh() }

    // Then schedule periodic checks
    timer = Timer.scheduledTimer(withTimeInterval: refreshInterval, repeats: true) {
      [weak self] _ in
      guard let self = self else { return }
      Task { @MainActor in
        await self.refresh()
      }
    }
  }

  /// Stop periodic status checks.
  func stopPolling() {
    timer?.invalidate()
    timer = nil
  }

  /// Perform a single status check.
  func refresh() async {
    status = await StatusChecker.check(repoPath: repoPath, runner: runner)
  }
}
