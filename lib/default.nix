# lib/default.nix — Public API surface for the configuration.
#
# Every helper is a pure function. The attribute set returned here is
# the *only* interface the rest of the repo consumes from `lib`.
{ nixpkgs, nixpkgs-unstable, home-manager, noctalia, sops-nix, noctalia-greeter, nixvim, llm-agents }:
let
  nixpkgsLib = nixpkgs.lib;

  # ── Channel builder (pure: system/overlays/config → stable + unstable) ──
  channels = import ./channels.nix {
    inherit nixpkgs nixpkgs-unstable;
  };

  # ── Host constructor (pure: system → NixOS configuration) ───────────────
  mkHost = import ./mkHost.nix {
    inherit nixpkgsLib home-manager noctalia sops-nix noctalia-greeter nixvim llm-agents;
  };

  # ── Pure color palettes table ──────────────────────────────────────────
  palettes = import ./palettes.nix;

in
{
  inherit nixpkgsLib channels mkHost palettes;
}
