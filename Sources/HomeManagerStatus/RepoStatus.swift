import SwiftUI

/// Represents the current status of the jj repository relative to trunk().
struct RepoStatus: Equatable, Sendable {
  /// Number of commits on the current working copy ancestry that are not on trunk().
  let ahead: Int
  /// Number of commits on trunk() that are not on the current working copy ancestry.
  let behind: Int
  /// Whether the working copy has uncommitted changes (non-empty).
  let dirty: Bool
  /// If non-nil, an error occurred while checking status.
  let error: String?

  /// The last time this status was successfully checked.
  let checkedAt: Date

  // MARK: - Convenience initializers

  static func synced(dirty: Bool = false, at date: Date = .now) -> RepoStatus {
    RepoStatus(ahead: 0, behind: 0, dirty: dirty, error: nil, checkedAt: date)
  }

  static func error(_ message: String, at date: Date = .now) -> RepoStatus {
    RepoStatus(ahead: 0, behind: 0, dirty: false, error: message, checkedAt: date)
  }

  // MARK: - Computed properties

  var isSynced: Bool { ahead == 0 && behind == 0 && error == nil }
  var isAhead: Bool { ahead > 0 && error == nil }
  var isBehind: Bool { behind > 0 && error == nil }
  var isDiverged: Bool { ahead > 0 && behind > 0 && error == nil }
  var hasError: Bool { error != nil }

  /// The SF Symbol name to display in the menu bar.
  var menuBarIcon: String {
    if hasError {
      return "exclamationmark.triangle.fill"
    }
    if isDiverged {
      return "arrow.up.arrow.down.circle.fill"
    }
    if isAhead {
      return "arrow.up.circle.fill"
    }
    if isBehind {
      return "arrow.down.circle.fill"
    }
    return "checkmark.circle.fill"
  }

  /// The color for the menu bar icon.
  var menuBarColor: Color {
    if hasError { return .red }
    if isDiverged { return .yellow }
    if isAhead { return .blue }
    if isBehind { return .orange }
    return .green
  }

  /// Compact text shown next to the icon in the menu bar.
  var menuBarText: String {
    if hasError { return "!" }
    if isDiverged { return "\u{2191}\(ahead)\u{2193}\(behind)" }
    if isAhead { return "\u{2191}\(ahead)" }
    if isBehind { return "\u{2193}\(behind)" }
    return ""
  }

  /// Full text for the menu bar label (icon is handled separately via Image).
  var menuBarLabel: String {
    var label = menuBarText
    if dirty && !hasError {
      label += "\u{25CF}"  // ● dot
    }
    return label
  }

  /// Human-readable status description for the dropdown.
  var statusDescription: String {
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
