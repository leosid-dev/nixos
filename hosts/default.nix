# hosts/default.nix — Auto-discovers host directories → nixosConfigurations.
#
# Third-party inputs (home-manager, noctalia, sops-nix, noctalia-greeter) are
# closed over by lib.mkHost, so hosts only need `lib` + `nixpkgsLib`.
{ lib, nixpkgsLib }:
let
  entries = builtins.readDir ./.;
  hostNames = nixpkgsLib.filter (name: entries.${name} == "directory") (
    nixpkgsLib.attrNames entries
  );
in
nixpkgsLib.genAttrs hostNames (
  name: import (./. + "/${name}") { inherit lib; }
)
