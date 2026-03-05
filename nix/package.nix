{
  lib,
  swift,
  swiftpm,
  apple-sdk_14,
}:

swift.stdenv.mkDerivation {
  pname = "home-manager-status";
  version = "0.1.0";

  src = lib.fileset.toSource {
    root = ./..;
    fileset = lib.fileset.unions [
      ./../Package.swift
      ./../Sources
      ./../Tests
      ./../Info.plist
    ];
  };

  nativeBuildInputs = [
    swift
    swiftpm
  ];

  buildInputs = [
    apple-sdk_14
  ];

  # Tests cannot run during nix build: SwiftPM's `swift-test` requires
  # `xcrun --find xctest` which needs Xcode, and corelibs-xctest in nix
  # only provides the library, not the runner. No Swift package in nixpkgs
  # has solved this — all have doCheck disabled or commented out.
  doCheck = false;

  # buildPhase is provided automatically by swiftpm's setup hook:
  #   swift-build -c release

  installPhase = ''
    runHook preInstall

    binPath="$(swiftpmBinPath)"
    APP="$out/Applications/HomeManagerStatus.app"
    mkdir -p "$APP/Contents/MacOS"

    cp "$binPath/HomeManagerStatus" "$APP/Contents/MacOS/HomeManagerStatus"
    cp ${./../Info.plist} "$APP/Contents/Info.plist"

    runHook postInstall
  '';

  meta = {
    description = "macOS menu bar app showing jj repo status for home-manager";
    platforms = lib.platforms.darwin;
  };
}
