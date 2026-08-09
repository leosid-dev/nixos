# modules/home/theme.nix — GTK, QT, cursor, and dconf theming (HM-level).
#
# Generic GTK/QT/cursor/dconf theming. The accent palette and specific
# font/cursor choices come from a profile or host-level override; defaults
# are Adwaita + Inter.
{ config, lib, pkgs, ... }:
let
  cfg = config.aspects.home.theme;
  theme = config.aspects.theme;
in
{
  options.aspects.home.theme = {
    enable = lib.mkEnableOption "GTK / QT / cursor / dconf theming";
  };

  options.aspects.theme = {
    font = {
      name = lib.mkOption {
        type = lib.types.str;
        default = "Inter";
      };
      package = lib.mkOption {
        type = lib.types.package;
        default = pkgs.inter;
      };
      size = lib.mkOption {
        type = lib.types.int;
        default = 11;
      };
    };

    cursor = {
      name = lib.mkOption {
        type = lib.types.str;
        default = "Adwaita";
      };
      package = lib.mkOption {
        type = lib.types.package;
        default = pkgs.adwaita-icon-theme;
      };
      size = lib.mkOption {
        type = lib.types.int;
        default = 24;
      };
    };

    accent = lib.mkOption {
      type = lib.types.str;
      default = "adwaita";
      description = ''
        Accent palette name. Currently selects GTK theme name only
        (adwaita | catppuccin-mocha | ...); toolkit-specific palettes are
        a future extension.
      '';
    };

    mode = lib.mkOption {
      type = lib.types.enum [ "dark" "light" ];
      default = "dark";
    };
  };

  config = lib.mkIf cfg.enable {
    gtk = {
      enable = true;
      theme = {
        name = if theme.accent == "adwaita" then "Adwaita" else theme.accent;
        package = pkgs.gnome-themes-extra;
      };
      iconTheme = {
        name = "Adwaita";
        package = pkgs.adwaita-icon-theme;
      };
      font = {
        name = theme.font.name;
        package = theme.font.package;
        size = theme.font.size;
      };
      cursorTheme = {
        name = theme.cursor.name;
        package = theme.cursor.package;
        size = theme.cursor.size;
      };
    };

    qt = {
      enable = true;
      platformTheme.name = "gtk3";
      style.name = "Fusion";
    };

    home.pointerCursor = {
      name = theme.cursor.name;
      package = theme.cursor.package;
      size = theme.cursor.size;
      gtk.enable = true;
    };

    dconf.settings."org/gnome/desktop/interface" = {
      color-scheme = if theme.mode == "dark" then "prefer-dark" else "prefer-light";
      gtk-theme = if theme.accent == "adwaita" then "Adwaita" else theme.accent;
      icon-theme = "Adwaita";
      cursor-theme = theme.cursor.name;
      cursor-size = theme.cursor.size;
      font-name = "${theme.font.name} ${toString theme.font.size}";
    };
  };
}
