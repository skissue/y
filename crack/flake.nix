{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
  };

  outputs = {
    self,
    nixpkgs,
  }: let
    forAllSystems = f:
      nixpkgs.lib.genAttrs ["x86_64-linux" "aarch64-linux"] (system: f nixpkgs.legacyPackages.${system});
  in {
    overlays.default = final: prev: {
      crack = final.callPackage ./default.nix {};
    };

    packages = forAllSystems (pkgs: rec {
      crack = pkgs.callPackage ./default.nix {};
      default = crack;
    });

    devShells = forAllSystems (pkgs: {
      default = with pkgs;
        mkShell {
          nativeBuildInputs = [rustc cargo];
          buildInputs = [rustfmt];
        };
    });
  };
}
