import Foundation

/// Protocol for running jj commands. Abstracted for testability.
public protocol JujutsuCommandRunner {
  /// Run a jj command with the given arguments against a repository.
  ///
  /// - Parameters:
  ///   - args: Arguments to pass to jj (e.g., ["log", "-r", "trunk()"])
  ///   - repoPath: Path to the repository
  /// - Returns: The stdout output of the command
  /// - Throws: If the command fails or jj is not found
  func run(args: [String], repoPath: String) async throws -> String
}

/// Real implementation that executes jj via Process.
public struct LiveJujutsuCommandRunner: JujutsuCommandRunner {
  /// Additional paths to add to the PATH environment variable.
  /// Needed because macOS GUI apps don't inherit the user's shell PATH.
  public let additionalPaths: [String]

  public init(additionalPaths: [String] = []) {
    self.additionalPaths = additionalPaths
  }

  /// Discover a reasonable set of Nix-aware PATH entries for the current user.
  public static func nixAwarePaths() -> [String] {
    let home = FileManager.default.homeDirectoryForCurrentUser.path
    return [
      "\(home)/.nix-profile/bin",
      "/nix/var/nix/profiles/default/bin",
      "/run/current-system/sw/bin",
      "/usr/local/bin",
      "/usr/bin",
      "/bin",
    ]
  }

  /// Search PATH directories for an executable named `name`.
  static func findExecutable(named name: String, in paths: [String]) -> String? {
    let fm = FileManager.default
    for dir in paths {
      let candidate = "\(dir)/\(name)"
      if fm.isExecutableFile(atPath: candidate) {
        return candidate
      }
    }
    return nil
  }

  public func run(args: [String], repoPath: String) async throws -> String {
    try await withCheckedThrowingContinuation { continuation in
      let process = Process()

      // Build the full PATH (extra paths + existing PATH)
      var env = ProcessInfo.processInfo.environment
      let existingPath = env["PATH"] ?? "/usr/bin:/bin"
      let extraPaths =
        additionalPaths.isEmpty
        ? Self.nixAwarePaths()
        : additionalPaths
      let fullPath = (extraPaths + [existingPath]).joined(separator: ":")
      let searchDirs = fullPath.components(separatedBy: ":")

      // Find jj on PATH directly instead of relying on /usr/bin/env
      // (which doesn't exist in nix sandboxes on Linux).
      guard let jjPath = Self.findExecutable(named: "jj", in: searchDirs) else {
        continuation.resume(
          throwing: CommandError.launchFailed("jj not found in PATH: \(fullPath)"))
        return
      }

      process.executableURL = URL(fileURLWithPath: jjPath)
      process.arguments = args

      env["PATH"] = fullPath
      process.environment = env

      process.currentDirectoryURL = URL(fileURLWithPath: repoPath)

      let stdout = Pipe()
      let stderr = Pipe()
      process.standardOutput = stdout
      process.standardError = stderr

      do {
        try process.run()
      } catch {
        continuation.resume(throwing: CommandError.launchFailed(error.localizedDescription))
        return
      }

      process.waitUntilExit()

      let outData = stdout.fileHandleForReading.readDataToEndOfFile()
      let errData = stderr.fileHandleForReading.readDataToEndOfFile()
      let outString = String(data: outData, encoding: .utf8) ?? ""
      let errString = String(data: errData, encoding: .utf8) ?? ""

      if process.terminationStatus != 0 {
        continuation.resume(
          throwing: CommandError.nonZeroExit(
            status: process.terminationStatus,
            stderr: errString.trimmingCharacters(in: .whitespacesAndNewlines)
          ))
      } else {
        continuation.resume(returning: outString)
      }
    }
  }

  public enum CommandError: LocalizedError {
    case launchFailed(String)
    case nonZeroExit(status: Int32, stderr: String)

    public var errorDescription: String? {
      switch self {
      case .launchFailed(let reason):
        return "Failed to launch jj: \(reason)"
      case .nonZeroExit(let status, let stderr):
        return "jj exited with status \(status): \(stderr)"
      }
    }
  }
}
