# lib/mkHost.nix — Pure host constructor.
#
# Accepts { system, channels, users, modules } and produces a
# nixpkgs.lib.nixosSystem value. Home Manager is wired in automatically.
{ nixpkgsLib, home-manager, noctalia }:
{ system, channels, users, modules }:
nixpkgsLib.nixosSystem {
  inherit system;

  specialArgs = {
    inherit channels noctalia;
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
    ]
    ++ modules;
}
