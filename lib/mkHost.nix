# lib/mkHost.nix — Pure host constructor.
#
# Accepts { system, channels, users, modules } and produces a
# nixpkgs.lib.nixosSystem value. Home Manager, sops-nix and the noctalia
# greeter are wired in automatically (each is inert without configuration).
{ nixpkgsLib, home-manager, noctalia, sops-nix, noctalia-greeter }:
{ system, channels, users, modules }:
nixpkgsLib.nixosSystem {
  inherit system;

  specialArgs = {
    inherit noctalia;
  };

  modules =
    [
      # Pin nixpkgs to our channel-constructed package set
      { nixpkgs.pkgs = channels.stable; }

      # Wire Home Manager as a NixOS module
      home-manager.nixosModules.home-manager
      {
        home-manager = {
          useGlobalPkgs = true;
          useUserPackages = true;
          extraSpecialArgs = { inherit noctalia; };
          users = users;
        };
      }

      # Third-party system modules (inert until configured)
      sops-nix.nixosModules.sops
      noctalia-greeter.nixosModules.default
    ]
    ++ modules;
}
