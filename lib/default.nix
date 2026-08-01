# lib/default.nix — Public API surface for the configuration.
#
# Every helper is a pure function. The attribute set returned here is
# the *only* interface the rest of the repo consumes from `lib`.
{ nixpkgs, nixpkgs-unstable, home-manager, noctalia }:
let
  nixpkgsLib = nixpkgs.lib;

  # ── Overlay combinators ─────────────────────────────────────────
  overlayHelpers = import ./overlays.nix { inherit nixpkgsLib; };

  # ── Channel builder (stable + unstable pkgs for a given system) ─
  channels = import ./channels.nix {
    inherit nixpkgs nixpkgs-unstable;
    inherit (overlayHelpers) applyOverlays;
  };

  # ── Host constructor (pure: system → NixOS configuration) ───────
  mkHost = import ./mkHost.nix {
    inherit nixpkgsLib home-manager noctalia;
  };

in
{
  inherit nixpkgsLib channels mkHost;
  inherit (overlayHelpers) applyOverlays;
}
