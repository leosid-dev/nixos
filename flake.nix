{
  description = "Agnostic, aspect-oriented NixOS configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    noctalia = {
      url = "github:noctalia-dev/noctalia/cachix";
    };

    noctalia-greeter = {
      url = "github:noctalia-dev/noctalia-greeter";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixvim = {
      url = "github:nix-community/nixvim/nixos-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Apple San Francisco fonts (SF Pro UI + SF Mono terminal). Not in
    # nixpkgs; this flake packages the official DMGs from Apple's CDN and
    # exposes them via overlays.default (pkgs.sf-pro, pkgs.sf-mono, ...).
    apple-fonts = {
      url = "github:Lyndeno/apple-fonts.nix";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };

    # LLM coding agents (opencode, grok, ...). Deliberately does NOT follow
    # our stable nixpkgs: upstream builds/tests only against its own pinned
    # nixpkgs-unstable, and following a stable branch would break. Keeping
    # the pin also lets us substitute from cache.numtide.com.
    llm-agents = {
      url = "github:numtide/llm-agents.nix";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      nixpkgs-unstable,
      home-manager,
      noctalia,
      noctalia-greeter,
      sops-nix,
      nixvim,
      llm-agents,
      apple-fonts,
      ...
    }:
    let
      lib = import ./lib {
        inherit
          nixpkgs
          nixpkgs-unstable
          home-manager
          noctalia
          noctalia-greeter
          sops-nix
          nixvim
          llm-agents
          apple-fonts
          ;
      };

      hosts = import ./hosts {
        inherit lib;
        nixpkgsLib = nixpkgs.lib;
      };

      supportedSystems = [
        "x86_64-linux"
        "aarch64-linux"
      ];
    in
    {
      nixosConfigurations = hosts;

      # Flake checks (agnostic static verification)
      checks = nixpkgs.lib.genAttrs supportedSystems (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
        in
        {
          easyeffects-preset = pkgs.runCommand "validate-easyeffects-preset" {
            nativeBuildInputs = [ pkgs.jq ];
          } ''
            ${pkgs.jq}/bin/jq -e '
              .output as $o |
              ($o.plugins_order | type == "array" and length > 0) and
              ($o.blocklist | type == "array") and
              all($o.plugins_order[]; . as $id | $o | has($id))
            ' ${./assets/easyeffects/dolby-approximation.json} >/dev/null
            touch $out
          '';
        }
      );

      # Re-export lib for external consumers / debugging
      lib = lib;
    };
}
