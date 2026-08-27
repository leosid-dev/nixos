# modules/home/nautilus.nix — Nautilus file manager & Sushi previewer (HM-level).
#
# Provides: GNOME Files (Nautilus), Sushi (space-bar quick preview),
# thumbnailers, MIME associations, and dconf defaults.
# Gated by aspects.home.nautilus.enable.
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.aspects.home.nautilus;
in
{
  options.aspects.home.nautilus = {
    enable = lib.mkEnableOption "Nautilus file manager";

    defaultView = lib.mkOption {
      type = lib.types.enum [
        "grid-view"
        "list-view"
      ];
      default = "grid-view";
      description = "Default folder view style in Nautilus.";
    };

    showHidden = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Whether to show hidden dotfiles by default (Ctrl+H toggles).";
    };
  };

  config = lib.mkIf cfg.enable {
    # Nautilus must see both the GVFS volume monitors (including MTP) and the
    # dconf GIO backend. Keep this scoped to the file-manager persona rather
    # than adding it to every graphical session.
    home.sessionVariables.GIO_EXTRA_MODULES = lib.makeSearchPath "lib/gio/modules" [
      pkgs.gvfs
      pkgs.dconf.lib
    ];

    home.packages = with pkgs; [
      nautilus
      ffmpegthumbnailer
      webp-pixbuf-loader
    ];

    # Register Nautilus as the default file manager for directories
    xdg.mimeApps = {
      enable = true;
      defaultApplications = {
        "inode/directory" = [ "org.gnome.Nautilus.desktop" ];
      };
    };
    xdg.configFile."mimeapps.list".force = true;
    xdg.dataFile."applications/mimeapps.list".force = true;

    # Nautilus preferences via dconf
    dconf.settings = {
      "org/gnome/nautilus/preferences" = {
        default-folder-viewer = cfg.defaultView;
        show-delete-permanently = true;
        show-create-link = true;
      };

      "org/gnome/nautilus/list-view" = {
        use-tree-view = true;
      };

      "org/gtk/gtk4/settings/file-chooser" = {
        show-hidden = cfg.showHidden;
        sort-directories-first = true;
      };

      "org/gtk/settings/file-chooser" = {
        show-hidden = cfg.showHidden;
        sort-directories-first = true;
      };
    };
  };
}
