# modules/system/core/nix.nix — Nix daemon, flakes, GC, store optimisation.
{ lib, config, pkgs, ... }:
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
      extra-trusted-public-keys = [
        "noctalia.cachix.org-1:pCOR47nnMEo5thcxNDtzWpOxNFQsBRglJzxWPp3dkU4="
        "niks3.numtide.com-1:DTx8wZduET09hRmMtKdQDxNNthLQETkc/yaX7M4qK0g="
      ];

      # Deduplicate hardlinks as paths land in the store — keeps the store
      # small between optimiser runs instead of only after weekly GC.
      auto-optimise-store = true;

      # Full local parallelism (explicit, so the daemon never falls back
      # to conservative values on laptops).
      max-jobs = "auto";
      cores = 0;
    };

    nix.gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 14d";
    };

    nix.optimise.automatic = true;

    # Prune old NixOS system-profile generations. There is no native
    # option for this on systemd-boot (limine/refind only), so a oneshot
    # runs at every boot and keeps the same number of generations as
    # systemd-boot's configurationLimit — one source of truth.
    systemd.services.nixos-generation-limit = {
      description = "Prune system-profile generations beyond boot.loader.systemd-boot.configurationLimit";
      wantedBy = [ "multi-user.target" ];
      serviceConfig.Type = "oneshot";
      script = ''
        ${pkgs.nix}/bin/nix-env \
          -p /nix/var/nix/profiles/system \
          --delete-generations +${toString config.boot.loader.systemd-boot.configurationLimit} \
          || true
      '';
    };

    # NOTE: unfree package policy is passed by each host into `lib.channels`
    # (channels config.allowUnfree), because nixpkgs.pkgs is externally
    # constructed — setting nixpkgs.config here would fail evaluation.
  };
}
