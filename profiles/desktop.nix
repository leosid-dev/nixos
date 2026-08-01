# profiles/desktop.nix — Home Manager profile for desktop users.
#
# Composes the home modules needed for a full desktop experience.
# Imported by hosts/*/users.nix for desktop users.
{
  imports = [
    ../modules/home/shell.nix
    ../modules/home/theme.nix
    ../modules/home/desktop.nix
    ../modules/home/noctalia.nix
    ../modules/home/audio.nix
  ];
}
