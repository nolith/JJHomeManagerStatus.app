import Foundation

/// Pure functions for parsing jj command output into RepoStatus.
public enum StatusParser {
  /// Parse the output of `jj log` that lists one commit description per line.
  ///
  /// - Parameter output: Raw stdout from jj log command
  /// - Returns: Number of commits and their first-line descriptions
  public static func parseCommitLines(from output: String) -> (count: Int, descriptions: [String]) {
    let trimmed = output.trimmingCharacters(in: .whitespacesAndNewlines)
    if trimmed.isEmpty {
      return (0, [])
    }
    let lines = trimmed.components(separatedBy: "\n")
    return (lines.count, lines)
  }

  /// Parse the output of the dirty-check command.
  ///
  /// - Parameter output: Raw stdout, expected to be "clean" or "dirty"
  /// - Returns: `true` if the working copy has changes, `false` if clean
  /// - Throws: If the output is unexpected
  public static func parseDirtyStatus(from output: String) throws -> Bool {
    let trimmed = output.trimmingCharacters(in: .whitespacesAndNewlines)
    switch trimmed {
    case "clean":
      return false
    case "dirty":
      return true
    default:
      throw ParserError.unexpectedDirtyOutput(trimmed)
    }
  }

  /// Build a RepoStatus from the three jj command outputs.
  ///
  /// - Parameters:
  ///   - aheadOutput: Output from the "commits ahead of trunk" command
  ///   - behindOutput: Output from the "commits behind trunk" command
  ///   - dirtyOutput: Output from the "dirty check" command
  ///   - date: Timestamp for the check (defaults to now)
  /// - Returns: A fully populated RepoStatus
  public static func parse(
    aheadOutput: String,
    behindOutput: String,
    dirtyOutput: String,
    at date: Date = Date()
  ) -> RepoStatus {
    let (ahead, aheadCommits) = parseCommitLines(from: aheadOutput)
    let (behind, behindCommits) = parseCommitLines(from: behindOutput)

    let dirty: Bool
    do {
      dirty = try parseDirtyStatus(from: dirtyOutput)
    } catch {
      return RepoStatus.error(
        "Failed to parse working copy status: \(error.localizedDescription)",
        at: date
      )
    }

    return RepoStatus(
      ahead: ahead,
      behind: behind,
      dirty: dirty,
      error: nil,
      aheadCommits: aheadCommits,
      behindCommits: behindCommits,
      checkedAt: date
    )
  }

  public enum ParserError: LocalizedError {
    case unexpectedDirtyOutput(String)

    public var errorDescription: String? {
      switch self {
      case .unexpectedDirtyOutput(let output):
        return "Unexpected dirty status output: '\(output)'"
      }
    }
  }
}
