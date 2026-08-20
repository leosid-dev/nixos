# modules/home/theme.nix — GTK, QT, cursor, and dconf theming (HM-level).
#
# Generic GTK/QT/cursor/dconf theming and cross-cutting theme options.
# Declares the canonical palette, font stack, cursor, mode, and accent choice.
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.aspects.home.theme;
  theme = config.aspects.theme;
  palettes = import ../../lib/palettes.nix;
  selected = palettes.${theme.accent}.${theme.mode};
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
        description = "Primary UI font family name (shared with greeter and desktop UI).";
      };
      package = lib.mkOption {
        type = lib.types.package;
        default = pkgs.inter;
        description = ''
          Package providing the primary quasi-proportional UI font.
        '';
      };
      size = lib.mkOption {
        type = lib.types.int;
        default = 12;
        description = "Base font size for desktop UI.";
      };
      monospace = {
        name = lib.mkOption {
          type = lib.types.str;
          default = "JetBrains Mono";
          description = "Monospace font family for terminals and code (Kitty, Neovim).";
        };
        package = lib.mkOption {
          type = lib.types.package;
          default = pkgs.jetbrains-mono;
          description = ''
            Package providing the terminal-optimized monospace font.
          '';
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
      type = lib.types.enum [
        "monochrome"
        "catppuccin-mocha"
        "adwaita"
      ];
      default = "monochrome";
      description = ''
        Accent palette name; the single source of truth for colors across
        Noctalia (palette), Kitty (terminal colors) and Neovim (colorscheme).
      '';
    };

    mode = lib.mkOption {
      type = lib.types.enum [
        "dark"
        "light"
      ];
      default = "dark";
      description = "Theme mode (dark or light surface colors).";
    };

    palette = {
      background = lib.mkOption {
        type = lib.types.str;
        default = selected.focus.background;
        description = "Main surface background color.";
      };
      foreground = lib.mkOption {
        type = lib.types.str;
        default = selected.terminal.foreground;
        description = "Primary text and foreground color.";
      };
      focus = {
        active = lib.mkOption {
          type = lib.types.str;
          default = selected.focus.active;
          description = "Active focus ring color.";
        };
        inactive = lib.mkOption {
          type = lib.types.str;
          default = selected.focus.inactive;
          description = "Inactive focus ring color.";
        };
        background = lib.mkOption {
          type = lib.types.str;
          default = selected.focus.background;
          description = "Workspace background color behind windows.";
        };
      };
      selection = {
        background = lib.mkOption {
          type = lib.types.str;
          default = selected.terminal.selectionBg;
          description = "Selection background color.";
        };
        foreground = lib.mkOption {
          type = lib.types.str;
          default = selected.terminal.selectionFg;
          description = "Selection foreground text color.";
        };
      };
      terminal = {
        foreground = lib.mkOption {
          type = lib.types.str;
          default = selected.terminal.foreground;
          description = "Terminal default foreground color.";
        };
        background = lib.mkOption {
          type = lib.types.str;
          default = selected.terminal.background;
          description = "Terminal default background color.";
        };
        cursor = lib.mkOption {
          type = lib.types.str;
          default = selected.terminal.cursor;
          description = "Terminal cursor color.";
        };
        cursorText = lib.mkOption {
          type = lib.types.str;
          default = selected.terminal.cursorText;
          description = "Terminal text color under cursor.";
        };
        selectionBg = lib.mkOption {
          type = lib.types.str;
          default = selected.terminal.selectionBg;
          description = "Terminal selection background color.";
        };
        selectionFg = lib.mkOption {
          type = lib.types.str;
          default = selected.terminal.selectionFg;
          description = "Terminal selection foreground color.";
        };
        normal = lib.mkOption {
          type = lib.types.attrsOf lib.types.str;
          default = selected.terminal.normal;
          description = "Terminal ANSI 8 standard colors.";
        };
        bright = lib.mkOption {
          type = lib.types.attrsOf lib.types.str;
          default = selected.terminal.bright;
          description = "Terminal ANSI 8 bright colors.";
        };
      };
      base16 = lib.mkOption {
        type = lib.types.nullOr (lib.types.attrsOf lib.types.str);
        default = selected.base16;
        description = "Base16 color palette mapping (base00..base0F). Defined for monochrome; null for others.";
      };
      opacity = lib.mkOption {
        type = lib.types.float;
        default = selected.opacity;
        description = "Terminal window background opacity.";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    # The monospace family is referenced by name in Kitty/Neovim; install the
    # package here so it actually exists in the user's fontconfig.
    home.packages = [ theme.font.monospace.package ];

    gtk = {
      enable = true;
      # Use the dark variant of Adwaita in dark mode so GTK3 applications
      # and portals correctly pick up dark styles.
      theme = {
        name = if theme.mode == "dark" then "Adwaita-dark" else "Adwaita";
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
    };

    home.pointerCursor = {
      name = theme.cursor.name;
      package = theme.cursor.package;
      size = theme.cursor.size;
      gtk.enable = true;
    };

    dconf.settings."org/gnome/desktop/interface" = {
      color-scheme = if theme.mode == "dark" then "prefer-dark" else "prefer-light";
      gtk-theme = if theme.mode == "dark" then "Adwaita-dark" else "Adwaita";
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
