# modules/system/core/nix.nix — Nix daemon, flakes, GC, store optimisation.
{ lib, config, ... }:
{
  config = lib.mkIf config.aspects.core.enable {
    nix.settings = {
      experimental-features = [
        "nix-command"
        "flakes"
      ];

      # Binary caches (additive — official cache.nixos.org stays default)
      # - noctalia: shell + greeter packages
      # - numtide:  llm-agents.nix packages (opencode, grok, ...)
      extra-substituters = [
        "https://noctalia.cachix.org"
        "https://cache.numtide.com"
      ];
      trusted-public-keys = [
        "noctalia.cachix.org-1:pCOR47nnMEo5thcxNDtzWpOxNFQsBRglJzxWPp3dkU4="
        "niks3.numtide.com-1:DTx8wZduET09hRmMtKdQDxNNthLQETkc/yaX7M4qK0g="
      ];
    };

    nix.gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 14d";
    };

    nix.optimise.automatic = true;

    # NOTE: unfree package policy is passed by each host into `lib.channels`
    # (channels config.allowUnfree), because nixpkgs.pkgs is externally
    # constructed — setting nixpkgs.config here would fail evaluation.
  };
}
