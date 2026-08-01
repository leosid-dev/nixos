# modules/system/core/default.nix — Always-on system fundamentals.
#
# Provides:
#   - Nix daemon settings (flakes, gc, optimisation)
#   - Boot loader configuration
#   - Locale / timezone / console defaults
#   - Minimal system packages & secrets management
#   - nix-ld for dynamic binaries
#
# Gated by aspects.core.enable (default true). Disabling this aspect is only
# meaningful for exotic container/VM hosts — it should normally stay on.
{ lib, ... }:
{
  options.aspects.core.enable = lib.mkOption {
    type = lib.types.bool;
    default = true;
    description = "Enable core system fundamentals (nix, boot, locale, packages, secrets).";
  };

  imports = [
    ./nix.nix
    ./boot.nix
    ./locale.nix
    ./packages.nix
    ./secrets.nix
  ];
}
