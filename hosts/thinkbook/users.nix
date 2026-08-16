# hosts/thinkbook/users.nix — Home Manager user definitions.
#
# This is an attrset of { username = HM-module; } passed to
# home-manager.users in mkHost.
{
  sid = {
    imports = [ ../../profiles/desktop.nix ];

    # Home Manager itself must be added to the user's profile so the
    # managed `home-manager` command and activation survive a rebuild.
    programs.home-manager.enable = true;

    # Flake checkout path for the `rebuild` shell alias (host data)
    aspects.home.shell.flakePath = "/home/sid/nixos";

    home = {
      username = "sid";
      homeDirectory = "/home/sid";
      stateVersion = "26.05";
    };
  };
}
