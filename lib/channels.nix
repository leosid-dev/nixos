# lib/channels.nix — Pure channel constructor.
#
# { system, overlays, config? } -> { stable, unstable }
#
# No package set is ever merged or mutated. The `unstable` channel is attached
# to `stable` through a real overlay at construction (the canonical, pure way
# to extend a pkgs set), and package policy (e.g. allowUnfree) is passed in as
# data — never embedded in this function.
{ nixpkgs, nixpkgs-unstable }:
{ system, overlays, config ? { } }:
let
  mkChannel = source:
    import source { inherit system overlays config; };

  unstable = mkChannel nixpkgs-unstable;

  stable = import nixpkgs {
    inherit system config;
    overlays = overlays ++ [
      # Expose the unstable channel as pkgs.unstable for any module.
      (final: prev: { inherit unstable; })
    ];
  };
in
{
  inherit stable unstable;
}
