# lib/channels.nix — Build stable + unstable package sets for a given system.
#
# Returns { stable, unstable } where `stable` is the primary pkgs set and
# `stable.unstable` is a convenience alias for cross-channel access.
{ nixpkgs, nixpkgs-unstable, applyOverlays }:
{ system, overlays }:
let
  stable = applyOverlays nixpkgs system overlays;
  unstable = applyOverlays nixpkgs-unstable system overlays;
in
{
  inherit unstable;
  stable = stable // { inherit unstable; };
}
