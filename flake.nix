{
  description = "HomeManagerStatus — macOS menu bar app for jj repo status";

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
          ...
        }:
        {
          packages = lib.optionalAttrs pkgs.stdenv.hostPlatform.isDarwin {
            default = pkgs.swiftPackages.callPackage ./nix/package.nix { };
          };

          treefmt = {
            projectRootFile = "flake.nix";
            programs = {
              nixfmt.enable = true;
              shfmt.enable = true;
              swift-format.enable = true;
            };
          };

          devShells.default = pkgs.mkShell {
            packages = with pkgs; [
              swift-format
            ];
          };
        };
    };
}
