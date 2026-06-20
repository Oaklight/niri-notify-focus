{
  description = "Focus source window on notification click for the niri Wayland compositor";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs =
    { self, nixpkgs }:
    let
      systems = [
        "x86_64-linux"
        "aarch64-linux"
      ];
      forAllSystems = nixpkgs.lib.genAttrs systems;
      pkgsFor = system: nixpkgs.legacyPackages.${system};
    in
    {
      packages = forAllSystems (system: rec {
        niri-notify-focus = (pkgsFor system).callPackage ./nix/package.nix { };
        default = niri-notify-focus;
      });

      overlays.default = _final: prev: {
        niri-notify-focus = prev.callPackage ./nix/package.nix { };
      };

      homeManagerModules = rec {
        niri-notify-focus = import ./nix/hm-module.nix self;
        default = niri-notify-focus;
      };

      formatter = forAllSystems (system: (pkgsFor system).nixfmt-rfc-style);
    };
}
