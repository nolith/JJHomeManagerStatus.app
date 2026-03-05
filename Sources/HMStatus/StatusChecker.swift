import Foundation

/// Single-shot jj status check. Cross-platform (no Apple frameworks).
public enum StatusChecker {
  /// Perform a single status check against a jj repository.
  ///
  /// - Parameters:
  ///   - repoPath: Path to the jj repository
  ///   - runner: Command runner to use (defaults to LiveJujutsuCommandRunner)
  ///   - date: Timestamp for the check (defaults to now)
  /// - Returns: A fully populated RepoStatus
  public static func check(
    repoPath: String,
    runner: JujutsuCommandRunner = LiveJujutsuCommandRunner(),
    at date: Date = Date()
  ) async -> RepoStatus {
    do {
      // Use @- (parent of working copy) to exclude the jj working copy
      // change itself — it's always present and its emptiness/dirtiness
      // is tracked separately via the dirty check below.
      async let aheadOutput = runner.run(
        args: [
          "log",
          "-r", "::@- ~ ::trunk()",
          "--no-graph",
          "-T", "commit_id.short() ++ \"\\n\"",
        ],
        repoPath: repoPath
      )

      async let behindOutput = runner.run(
        args: [
          "log",
          "-r", "::trunk() ~ ::@-",
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
      return StatusParser.parse(
        aheadOutput: ahead,
        behindOutput: behind,
        dirtyOutput: dirty,
        at: date
      )
    } catch {
      return RepoStatus.error(error.localizedDescription, at: date)
    }
  }
}
