# hosts/default.nix — Auto-discover hosts from subdirectories.
#
# Each subdirectory under hosts/ is a machine. Its default.nix receives
# { lib, nixpkgsLib, home-manager, noctalia } and returns a NixOS config.
{ lib, nixpkgsLib, home-manager, noctalia }:
let
  entries = builtins.readDir ./.;
  hostNames = nixpkgsLib.filter (name: entries.${name} == "directory") (
    nixpkgsLib.attrNames entries
  );
in
nixpkgsLib.genAttrs hostNames (
  name:
  import (./. + "/${name}") {
    inherit lib home-manager noctalia;
  }
)
