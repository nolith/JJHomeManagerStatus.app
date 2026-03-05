{
  description = "HomeManagerStatus — macOS menu bar app and CLI for jj repo status";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    inputs:
    inputs.flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [
        "aarch64-darwin"
        "x86_64-darwin"
        "x86_64-linux"
      ];

      imports = [
        inputs.treefmt-nix.flakeModule
      ];

      flake = {
        homeManagerModules.default = import ./nix/modules/home-manager.nix;
        homeManagerModules.jj-home-manager-status = import ./nix/modules/home-manager.nix;
      };

      perSystem =
        {
          pkgs,
          lib,
          self',
          ...
        }:
        {
          packages =
            lib.packagesFromDirectoryRecursive {
              callPackage = pkgs.callPackage;
              directory = ./nix/pkgs;
            }
            // lib.optionalAttrs pkgs.stdenv.hostPlatform.isDarwin {
              default = self'.packages.app;
            };

          checks = {
            hm-status-integration = self'.packages.hm-status.tests.integration;
          };

          treefmt = {
            projectRootFile = "flake.nix";
            programs = {
              nixfmt.enable = true;
              shfmt.enable = true;
              swift-format.enable = true;
            };
          };

        };
    };
}
