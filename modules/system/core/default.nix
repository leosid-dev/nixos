# modules/system/core/default.nix — Always-on system fundamentals.
#
# This aspect is imported by every host. It provides:
#   - Nix daemon settings (flakes, gc, optimisation)
#   - Boot loader configuration
#   - Locale / timezone / console defaults
#   - nixpkgs.config (allowUnfree)
#   - Minimal system packages & secrets management
#   - nix-ld for dynamic binaries
{
  imports = [
    ./nix.nix
    ./boot.nix
    ./locale.nix
    ./packages.nix
    ./secrets.nix
  ];
}
