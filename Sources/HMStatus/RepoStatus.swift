import Foundation

/// Represents the current status of the jj repository relative to trunk().
public struct RepoStatus: Equatable {
  /// Number of commits on the current working copy ancestry that are not on trunk().
  public let ahead: Int
  /// Number of commits on trunk() that are not on the current working copy ancestry.
  public let behind: Int
  /// Whether the working copy has uncommitted changes (non-empty).
  public let dirty: Bool
  /// If non-nil, an error occurred while checking status.
  public let error: String?

  /// The last time this status was successfully checked.
  public let checkedAt: Date

  public init(ahead: Int, behind: Int, dirty: Bool, error: String?, checkedAt: Date) {
    self.ahead = ahead
    self.behind = behind
    self.dirty = dirty
    self.error = error
    self.checkedAt = checkedAt
  }

  // MARK: - Convenience initializers

  public static func synced(dirty: Bool = false, at date: Date = Date()) -> RepoStatus {
    RepoStatus(ahead: 0, behind: 0, dirty: dirty, error: nil, checkedAt: date)
  }

  public static func error(_ message: String, at date: Date = Date()) -> RepoStatus {
    RepoStatus(ahead: 0, behind: 0, dirty: false, error: message, checkedAt: date)
  }

  // MARK: - Computed properties

  public var isSynced: Bool { ahead == 0 && behind == 0 && error == nil }
  public var isAhead: Bool { ahead > 0 && error == nil }
  public var isBehind: Bool { behind > 0 && error == nil }
  public var isDiverged: Bool { ahead > 0 && behind > 0 && error == nil }
  public var hasError: Bool { error != nil }

  /// Compact text shown in the menu bar.
  public var menuBarText: String {
    if hasError { return "!" }
    if isDiverged { return "\u{2191}\(ahead)\u{2193}\(behind)" }
    if isAhead { return "\u{2191}\(ahead)" }
    if isBehind { return "\u{2193}\(behind)" }
    return ""
  }

  /// Full text for the menu bar label.
  public var menuBarLabel: String {
    var label = menuBarText
    if dirty && !hasError {
      label += "\u{25CF}"  // ● dot
    }
    if label.isEmpty {
      return "\u{2713}"  // ✓ checkmark
    }
    return label
  }

  /// Human-readable status description for the dropdown.
  public var statusDescription: String {
    if hasError {
      return "Error: \(error!)"
    }

    var parts: [String] = []

    if isSynced {
      parts.append("In sync with trunk")
    } else {
      if ahead > 0 {
        parts.append("\(ahead) commit\(ahead == 1 ? "" : "s") ahead of trunk")
      }
      if behind > 0 {
        parts.append("\(behind) commit\(behind == 1 ? "" : "s") behind trunk")
      }
    }

    if dirty {
      parts.append("Working copy has changes")
    } else if !hasError {
      parts.append("Working copy is clean")
    }

    return parts.joined(separator: "\n")
  }
}
