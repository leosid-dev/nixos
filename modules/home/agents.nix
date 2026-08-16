# modules/home/agents.nix — LLM coding agents from numtide/llm-agents.nix.
#
# Packages come straight from the flake's own package set (built against
# its pinned nixpkgs-unstable, substitutable from cache.numtide.com).
# Which agents to install is persona data: the profile (or a user) picks
# names from the flake catalog via aspects.home.agents.packages.
{ config, lib, pkgs, llm-agents, ... }:
let
  cfg = config.aspects.home.agents;

  # The flake's package catalog for this platform.
  catalog = llm-agents.packages.${pkgs.stdenv.hostPlatform.system};
in
{
  options.aspects.home.agents = {
    enable = lib.mkEnableOption "LLM coding agents";

    packages = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = ''
        Package names from numtide/llm-agents.nix to install. The catalog
        is updated daily upstream; unknown names fail evaluation with a
        clear error. Explicitly selected by profile or user.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = map
      (name:
        catalog.${name} or (throw "llm-agents.nix has no package '${name}' (check the upstream catalog)"))
      cfg.packages;
  };
}
