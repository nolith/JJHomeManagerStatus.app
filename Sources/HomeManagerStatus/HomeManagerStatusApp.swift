import AppKit
import HMStatus
import SwiftUI

@main
struct HomeManagerStatusApp: App {
  @StateObject private var checker: AppStatusChecker

  init() {
    // Hide from Dock — this is a menu bar-only app.
    // We set this programmatically because SPM executables don't have an Info.plist bundle.
    NSApplication.shared.setActivationPolicy(.accessory)

    let home = FileManager.default.homeDirectoryForCurrentUser.path
    let repoPath = "\(home)/.config/home-manager"
    let checkerInstance = AppStatusChecker(repoPath: repoPath)
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
  @ObservedObject var checker: AppStatusChecker
  @State private var ghosttyLaunchErrorMessage: String?

  private let ghosttyLauncher = GhosttyLauncher()

  private var formattedTime: String {
    checker.status.checkedAt.formatted(date: .omitted, time: .standard)
  }

  var body: some View {
    Group {
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
    .alert(
      "Unable to Open Ghostty",
      isPresented: Binding(
        get: { ghosttyLaunchErrorMessage != nil },
        set: { isPresented in
          if !isPresented {
            ghosttyLaunchErrorMessage = nil
          }
        }
      )
    ) {
      Button("OK", role: .cancel) {}
    } message: {
      Text(ghosttyLaunchErrorMessage ?? "Unknown error")
    }
  }

  private func openInGhostty(path: String) {
    do {
      try ghosttyLauncher.openNewWindow(path: path)
    } catch {
      ghosttyLaunchErrorMessage = error.localizedDescription
    }
  }
}

struct GhosttyLauncher {
  enum LaunchError: LocalizedError {
    case openCommandExecutionFailed(String)
    case openCommandFailed(String)

    var errorDescription: String? {
      switch self {
      case .openCommandExecutionFailed(let details):
        return "Could not run open for Ghostty. \(details)"
      case .openCommandFailed(let details):
        if details.isEmpty {
          return "Ghostty could not be opened. Make sure Ghostty is installed."
        }
        return "Ghostty could not be opened. \(details)"
      }
    }
  }

  func makeOpenArguments(path: String) -> [String] {
    let shell = ProcessInfo.processInfo.environment["SHELL"] ?? "/bin/zsh"
    let shellCommand = "cd \(shellQuoted(path)) && exec \(shellQuoted(shell))"
    return ["-n", "-a", "Ghostty", "--args", "-e", "/bin/sh", "-lc", shellCommand]
  }

  func openNewWindow(path: String) throws {
    let process = Process()
    process.executableURL = URL(fileURLWithPath: "/usr/bin/open")
    process.arguments = makeOpenArguments(path: path)

    let stderr = Pipe()
    process.standardError = stderr

    do {
      try process.run()
    } catch {
      throw LaunchError.openCommandExecutionFailed(error.localizedDescription)
    }

    process.waitUntilExit()

    guard process.terminationStatus == 0 else {
      let data = stderr.fileHandleForReading.readDataToEndOfFile()
      let output =
        String(data: data, encoding: .utf8)?
        .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
      throw LaunchError.openCommandFailed(output)
    }
  }

  private func shellQuoted(_ value: String) -> String {
    "'\(value.replacingOccurrences(of: "'", with: "'\\''"))'"
  }
}
