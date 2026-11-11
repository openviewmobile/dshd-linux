{
  description = "DeepSeek Harness desktop (AppImage wrapper) for Nix and NixOS";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs }:
    let
      systems = [ "x86_64-linux" "aarch64-linux" ];
      forAllSystems = f:
        nixpkgs.lib.genAttrs systems (system: f nixpkgs.legacyPackages.${system});
    in
    {
      packages = forAllSystems (pkgs: rec {
        deepseek-harness = pkgs.callPackage ./package.nix { };
        default = deepseek-harness;
      });

      apps = forAllSystems (pkgs: {
        default = {
          type = "app";
          program = "${self.packages.${pkgs.system}.deepseek-harness}/bin/deepseek-harness";
        };
      });

    };
}
