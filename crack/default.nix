{
  lib,
  rustPlatform,
}:
rustPlatform.buildRustPackage {
  pname = "crack";
  version = "0.1.0";

  cargoLock.lockFile = ./Cargo.lock;

  src = lib.cleanSource ./.;

  meta = {
    description = "Tiny CLI time tracker";
    license = lib.licenses.mit;
    mainProgram = "crack";
    platforms = lib.platforms.unix;
  };
}
