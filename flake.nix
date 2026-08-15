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
          ;
      };

      hosts = import ./hosts {
        inherit lib;
        nixpkgsLib = nixpkgs.lib;
      };
    in
    {
      nixosConfigurations = hosts;

      # Re-export lib for external consumers / debugging
      lib = lib;
    };
}
