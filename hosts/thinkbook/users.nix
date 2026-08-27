# hosts/thinkbook/users.nix — Home Manager user definitions.
#
# This is an attrset of { username = HM-module; } passed to
# home-manager.users in mkHost.
{
  sid = {
    imports = [
      ../../profiles/desktop.nix
      ../../profiles/thinkbook-audio.nix
      ../../profiles/thinkbook-noctalia.nix
    ];

    # Home Manager itself must be added to the user's profile so the
    # managed `home-manager` command and activation survive a rebuild.
    programs.home-manager.enable = true;

    # Flake checkout path for the `rebuild` shell alias (host data)
    aspects.home.shell.flakePath = "/home/sid/nixos";

    # Commit identity is persona data, owned here instead of git.nix
    programs.git.settings = {
      user.name = "SIDAHRTH P M";
      user.email = "beastsid2429@gmail.com";
    };

    # The built-in panel is 1920x1200 at 60 Hz. Pin the native mode and run
    # at 100% scaling: one logical pixel per physical pixel, no fractional
    # scaling cost, full use of the panel's workspace.
    aspects.home.niri.output = {
      name = "eDP-1";
      mode = "1920x1200@60.002";
      scale = 1.00;
    };

    home = {
      username = "sid";
      homeDirectory = "/home/sid";
      stateVersion = "26.05";
    };
  };
}
