{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.programs.jj-home-manager-status;
in
{
  options.programs.jj-home-manager-status = {
    enable = lib.mkEnableOption "HomeManagerStatus menu bar app for jj repo status";

    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.home-manager-status or null;
      defaultText = lib.literalExpression "pkgs.home-manager-status";
      description = "The HomeManagerStatus package to use.";
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = cfg.package != null;
        message = "programs.jj-home-manager-status.package must be set. Either add home-manager-status to your pkgs overlay or set this option directly.";
      }
    ];

    launchd.agents.HomeManagerStatus = {
      enable = true;
      config = {
        ProgramArguments = [
          "${cfg.package}/Applications/HomeManagerStatus.app/Contents/MacOS/HomeManagerStatus"
        ];
        RunAtLoad = true;
        KeepAlive = true;
      };
    };
  };
}
