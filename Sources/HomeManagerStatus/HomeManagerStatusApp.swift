import AppKit
import SwiftUI

@main
struct HomeManagerStatusApp: App {
  @StateObject private var checker: StatusChecker

  init() {
    // Hide from Dock — this is a menu bar-only app.
    // We set this programmatically because SPM executables don't have an Info.plist bundle.
    NSApplication.shared.setActivationPolicy(.accessory)

    let home = FileManager.default.homeDirectoryForCurrentUser.path
    let repoPath = "\(home)/.config/home-manager"
    let checkerInstance = StatusChecker(repoPath: repoPath)
    _checker = StateObject(wrappedValue: checkerInstance)

    // Start polling after a small delay to allow the app to finish launching.
    Task { @MainActor in
      checkerInstance.startPolling()
    }
  }

  var body: some Scene {
    MenuBarExtra {
      MenuContent(checker: checker)
    } label: {
      MenuBarLabel(status: checker.status)
    }
  }
}

// MARK: - Menu Bar Label

struct MenuBarLabel: View {
  let status: RepoStatus

  var body: some View {
    Text(status.menuBarLabel)
      .monospacedDigit()
  }
}

// MARK: - Menu Content

struct MenuContent: View {
  @ObservedObject var checker: StatusChecker

  private var formattedTime: String {
    checker.status.checkedAt.formatted(date: .omitted, time: .standard)
  }

  var body: some View {
    // Status section
    Section {
      ForEach(
        checker.status.statusDescription.components(separatedBy: "\n"), id: \.self
      ) { line in
        Text(line)
      }

      Text("Last checked: \(formattedTime)")
        .foregroundStyle(.secondary)
    }

    Divider()

    // Actions
    Section {
      Button("Refresh Now") {
        Task { await checker.refresh() }
      }
      .keyboardShortcut("r")

      Button("Open in Ghostty") {
        openInGhostty(path: checker.repoPath)
      }
      .keyboardShortcut("t")
    }

    Divider()

    Button("Quit") {
      NSApplication.shared.terminate(nil)
    }
    .keyboardShortcut("q")
  }

  private func openInGhostty(path: String) {
    let process = Process()
    process.executableURL = URL(fileURLWithPath: "/usr/bin/open")
    process.arguments = ["-a", "Ghostty", "--args", "-e", "cd \(path) && exec $SHELL"]
    try? process.run()
  }
}
