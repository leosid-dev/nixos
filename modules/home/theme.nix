# modules/home/theme.nix — GTK, QT, cursor, and dconf theming.
{ pkgs, ... }:
{
  gtk = {
    enable = true;
    theme = {
      name = "Adwaita";
      package = pkgs.gnome-themes-extra;
    };
    iconTheme = {
      name = "Adwaita";
      package = pkgs.adwaita-icon-theme;
    };
    font = {
      name = "Inter";
      package = pkgs.inter;
      size = 11;
    };
    cursorTheme = {
      name = "Adwaita";
      package = pkgs.adwaita-icon-theme;
      size = 24;
    };
  };

  qt = {
    enable = true;
    platformTheme.name = "gtk3";
    style.name = "Fusion";
  };

  home.pointerCursor = {
    name = "Adwaita";
    package = pkgs.adwaita-icon-theme;
    size = 24;
    gtk.enable = true;
  };

  dconf.settings."org/gnome/desktop/interface" = {
    color-scheme = "prefer-dark";
    gtk-theme = "Adwaita";
    icon-theme = "Adwaita";
    cursor-theme = "Adwaita";
    cursor-size = 24;
    font-name = "Inter 11";
  };
}
