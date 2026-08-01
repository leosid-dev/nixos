{
  description = "Agnostic, aspect-oriented NixOS configuration";

  inputs = {
    # ── Channel pins ──────────────────────────────────────────────
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";

    # ── Home Manager (follows stable) ─────────────────────────────
    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # ── Noctalia v5 (shell + login manager) ───────────────────────
    noctalia = {
      url = "github:noctalia-dev/noctalia/cachix";
    };
  };

  nixConfig = {
    extra-substituters = [ "https://noctalia.cachix.org" ];
    extra-trusted-public-keys = [
      "noctalia.cachix.org-1:pCOR47nnMEo5thcxNDtzWpOxNFQsBRglJzxWPp3dkU4="
    ];
  };

  outputs =
    {
      self,
      nixpkgs,
      nixpkgs-unstable,
      home-manager,
      noctalia,
      ...
    }:
    let
      # ── Lib: pure helper functions ──────────────────────────────
      lib = import ./lib {
        inherit
          nixpkgs
          nixpkgs-unstable
          home-manager
          noctalia
          ;
      };

      # ── Hosts: each subdirectory = one machine ──────────────────
      hosts = import ./hosts {
        inherit lib home-manager noctalia;
        nixpkgsLib = nixpkgs.lib;
      };
    in
    {
      nixosConfigurations = hosts;

      # Re-export lib for external consumers / debugging
      lib = lib;
    };
}
