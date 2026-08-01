# hosts/thinkbook/users.nix — Home Manager user definitions.
#
# This is an attrset of { username = HM-module; } passed to
# home-manager.users in mkHost.
{
  sid = {
    imports = [ ../../profiles/desktop.nix ];

    home = {
      username = "sid";
      homeDirectory = "/home/sid";
      stateVersion = "26.05";
    };
  };
}
