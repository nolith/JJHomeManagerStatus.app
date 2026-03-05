{
  lib,
  stdenv,
  swiftPackages,
  swift ? swiftPackages.swift,
  swiftpm ? swiftPackages.swiftpm,
  apple-sdk_14,
}:

swift.stdenv.mkDerivation {
  pname = "jj-home-manager-status";
  version = "0.1.0";

  src = lib.fileset.toSource {
    root = ../../..;
    fileset = lib.fileset.unions [
      ../../../Package.swift
      ../../../Sources
      ../../../Info.plist
    ];
  };

  nativeBuildInputs = [
    swift
    swiftpm
  ];

  buildInputs = [
    apple-sdk_14
  ];

  swiftpmFlags = [ "--product HomeManagerStatus" ];

  # swift-test cannot run in the nix sandbox (needs Xcode).
  # Integration tests run via the hm-status CLI package (passthru.tests).
  doCheck = false;

  installPhase = ''
    runHook preInstall

    binPath="$(swiftpmBinPath)"
    APP="$out/Applications/HomeManagerStatus.app"
    mkdir -p "$APP/Contents/MacOS"

    install -Dm755 "$binPath/HomeManagerStatus" "$APP/Contents/MacOS/HomeManagerStatus"
    install -Dm644 ${../../../Info.plist} "$APP/Contents/Info.plist"

    runHook postInstall
  '';

  meta = {
    description = "macOS menu bar app showing jj repo status for home-manager";
    mainProgram = "HomeManagerStatus";
    platforms = lib.platforms.darwin;
  };
}
