{
  lib,
  stdenv,
  swiftPackages,
  swift ? swiftPackages.swift,
  swiftpm ? swiftPackages.swiftpm,
  Foundation ? swiftPackages.Foundation,
  Dispatch ? swiftPackages.Dispatch,
  apple-sdk_14 ? null,
  runCommand,
  jujutsu,
  gitMinimal,
}:

swift.stdenv.mkDerivation (finalAttrs: {
  pname = "hm-status";
  version = "0.1.0";

  src = lib.fileset.toSource {
    root = ../../..;
    fileset = lib.fileset.unions [
      ../../../Package.swift
      ../../../Sources
    ];
  };

  nativeBuildInputs = [
    swift
    swiftpm
  ];

  buildInputs =
    lib.optionals stdenv.hostPlatform.isDarwin [
      apple-sdk_14
    ]
    ++ lib.optionals stdenv.hostPlatform.isLinux [
      Foundation
    ];

  env = lib.optionalAttrs stdenv.hostPlatform.isLinux {
    LD_LIBRARY_PATH = lib.makeLibraryPath [ Dispatch ];
  };

  swiftpmFlags = [ "--product hm-status" ];

  # swift-test cannot run in the nix sandbox (needs Xcode on macOS,
  # libIndexStore.so on Linux). Integration tests run via passthru.tests.
  doCheck = false;

  installPhase = ''
    runHook preInstall

    binPath="$(swiftpmBinPath)"
    install -Dm755 "$binPath/hm-status" "$out/bin/hm-status"

    runHook postInstall
  '';

  passthru.tests = {
    integration =
      let
        hm-status = finalAttrs.finalPackage;
      in
      runCommand "hm-status-integration-test"
        {
          nativeBuildInputs = [
            hm-status
            jujutsu
            gitMinimal
          ];
        }
        ''
          bash ${./integration-test.sh} ${lib.getExe hm-status}
          touch $out
        '';
  };

  meta = {
    description = "CLI tool showing jj repo status relative to trunk";
    mainProgram = "hm-status";
    platforms = lib.platforms.darwin ++ lib.platforms.linux;
  };
})
