import Foundation
import HMStatus

@main
struct HMStatusCLI {
  static func main() async {
    let args = CommandLine.arguments.dropFirst()

    var shortOutput = false
    var failOnOutOfSync = false
    var repoPath: String?

    for arg in args {
      switch arg {
      case "--short":
        shortOutput = true
      case "--fail":
        failOnOutOfSync = true
      case "--help", "-h":
        printUsage()
        exit(0)
      default:
        if arg.hasPrefix("-") {
          fputs("Unknown option: \(arg)\n", stderr)
          printUsage()
          exit(2)
        }
        repoPath = arg
      }
    }

    let path = repoPath ?? defaultRepoPath()

    let status = await StatusChecker.check(repoPath: path)

    if status.hasError {
      fputs("\(status.statusDescription)\n", stderr)
      exit(2)
    }

    if shortOutput {
      print(status.menuBarLabel)
    } else {
      print(status.statusDescription)
    }

    if failOnOutOfSync && !status.isSynced {
      exit(1)
    }
  }

  static func defaultRepoPath() -> String {
    let home = FileManager.default.homeDirectoryForCurrentUser.path
    return "\(home)/.config/home-manager"
  }

  static func printUsage() {
    let usage = """
      Usage: hm-status [OPTIONS] [PATH]

      Check jj repository status relative to trunk.

      Arguments:
        PATH    Path to jj repository (default: ~/.config/home-manager)

      Options:
        --short   Print compact status (e.g. ✓, ↑2●, ↓3)
        --fail    Exit with code 1 when out of sync
        --help    Show this help message

      Exit codes:
        0   Success (or out of sync without --fail)
        1   Out of sync (only with --fail)
        2   Error (jj not found, invalid repo, etc.)
      """
    print(usage)
  }
}
