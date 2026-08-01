# lib/overlays.nix — Pure overlay combinator functions.
{ nixpkgsLib }:
let
  composeAll = nixpkgsLib.foldr nixpkgsLib.composeExtensions (_final: _prev: { });
in
{
  # Apply a list of overlays to a nixpkgs input, returning a pkgs set.
  applyOverlays =
    source: system: overlays:
    source.legacyPackages.${system}.extend (composeAll overlays);
}
