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
      monospace = {
        name = lib.mkOption {
          type = lib.types.str;
          default = "JetBrains Mono";
          description = ''
            Monospace font family for terminals and code (Kitty, etc.).
            Kept separate from the UI font, which is proportional.
          '';
        };
        package = lib.mkOption {
          type = lib.types.package;
          default = pkgs.jetbrains-mono;
        };
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
      default = "monochrome";
      description = ''
        Accent palette name; the single source of truth for colors across
        Noctalia (palette), Kitty (terminal colors) and Neovim (colorscheme).
        Known values: monochrome (grayscale, true-black surfaces),
        catppuccin-mocha, adwaita. GTK apps always use the Adwaita theme
        (the only one installed); monochrome additionally selects the
        `slate` libadwaita accent (least saturated enum value).
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
      # Adwaita is the only GTK theme installed; the accent palette drives
      # Noctalia/Kitty/Neovim, not the GTK theme name.
      theme = {
        name = "Adwaita";
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
      gtk-theme = "Adwaita";
      icon-theme = "Adwaita";
      cursor-theme = theme.cursor.name;
      cursor-size = theme.cursor.size;
      font-name = "${theme.font.name} ${toString theme.font.size}";
    }
    // lib.optionalAttrs (theme.accent == "monochrome") {
      # Nearest monochrome named accent (the key is an enum, not a color).
      accent-color = "slate";
    };
  };
}
