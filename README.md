# HomeManagerStatus

A macOS menu bar app that shows the [Jujutsu (jj)](https://github.com/jj-vcs/jj) status of your `~/.config/home-manager` repository.

## What it does

- Displays ahead/behind status relative to `trunk()` in the menu bar
- Shows if the working copy has uncommitted changes
- Polls every 5 minutes with manual refresh available
- Quick action to open the repo in Ghostty terminal

## Target Audience

This app is for users who:

- Manage their dotfiles with [home-manager](https://github.com/nix-community/home-manager)
- Use Jujutsu (jj) for version control
- Run macOS 13+ (Ventura or later)

## Installation

### With home-manager (recommended)

Add the flake input to your `flake.nix`:

```nix
inputs.jj-home-manager-status = {
  url = "github:nolith/JJHomeManagerStatus.app";
  inputs.nixpkgs.follows = "nixpkgs";
};
```

Then enable the module in your home-manager configuration:

```nix
{ pkgs, jj-home-manager-status, ... }:
{
  imports = [ jj-home-manager-status.homeManagerModules.default ];

  programs.jj-home-manager-status = {
    enable = true;
    package = jj-home-manager-status.packages.${pkgs.system}.default;
  };
}
```

This configures a launchd user agent that starts the app at login and keeps it running.

### Manual build

```bash
# With Nix
nix build

# With Swift (for development)
swift build -c release
```

## Configuration Options

| Option    | Type    | Default                    | Description                        |
| --------- | ------- | -------------------------- | ---------------------------------- |
| `enable`  | bool    | `false`                    | Whether to enable the menu bar app |
| `package` | package | `pkgs.home-manager-status` | The package to use                 |

## Requirements

- macOS 13.0 or later
- Jujutsu (`jj`) installed and available in PATH
- A jj-managed repository at `~/.config/home-manager`
