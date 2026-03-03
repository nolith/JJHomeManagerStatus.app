import Foundation
import SwiftUI

/// Orchestrates periodic jj status checks and publishes results for the UI.
@MainActor
final class StatusChecker: ObservableObject {
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
            checkedAt: .now
        )
    }

    /// Start periodic status checks.
    func startPolling() {
        // Run immediately
        Task { await refresh() }

        // Then schedule periodic checks
        timer = Timer.scheduledTimer(withTimeInterval: refreshInterval, repeats: true) {
            [weak self] _ in
            guard let self else { return }
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
        let now = Date.now

        do {
            async let aheadOutput = runner.run(
                args: [
                    "log",
                    "-r", "::@ ~ ::trunk()",
                    "--no-graph",
                    "-T", "commit_id.short() ++ \"\\n\"",
                ],
                repoPath: repoPath
            )

            async let behindOutput = runner.run(
                args: [
                    "log",
                    "-r", "::trunk() ~ ::@",
                    "--no-graph",
                    "-T", "commit_id.short() ++ \"\\n\"",
                ],
                repoPath: repoPath
            )

            async let dirtyOutput = runner.run(
                args: [
                    "log",
                    "-r", "@",
                    "--no-graph",
                    "-T", "if(empty, \"clean\", \"dirty\")",
                ],
                repoPath: repoPath
            )

            let (ahead, behind, dirty) = try await (aheadOutput, behindOutput, dirtyOutput)
            status = StatusParser.parse(
                aheadOutput: ahead,
                behindOutput: behind,
                dirtyOutput: dirty,
                at: now
            )
        } catch {
            status = RepoStatus.error(error.localizedDescription, at: now)
        }
    }
}
