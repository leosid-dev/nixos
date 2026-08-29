# modules/home/packages.nix — Common user applications.
#
# Always-on shared applications: the basic-desktop essentials (image
# viewer, document viewer, archive manager, GUI text editor), with
# deterministic MIME defaults pinned alongside (the directory pin lives
# in nautilus.nix, the media pins in mpv.nix). Also ships a "Neovim in
# Kitty" desktop entry so graphical file managers and choosers can
# launch the terminal editor.
{ config, lib, pkgs, ... }:
{
  home.packages = with pkgs; [
    loupe # image viewer (GNOME, GTK4)
    zathura # document viewer (PDF/epub; nixpkgs wraps it with plugins)
    file-roller # archive manager (nautilus extract/compress integration)
    gnome-text-editor # GUI text editor
  ];

  # The nixvim build is terminal-only, so graphical file choosers cannot
  # launch it. Provide a desktop entry that opens Neovim inside Kitty.
  # Declares no MimeType, so it never competes with the pinned
  # text/plain default — it only appears in "Open with".
  xdg.desktopEntries."neovim-kitty" = {
    name = "Neovim (Kitty)";
    exec = "${lib.getExe pkgs.kitty} ${lib.getExe config.programs.nixvim.build.package} %F";
    terminal = false;
    categories = [
      "Utility"
      "TextEditor"
    ];
  };

  # Deterministic default applications for the installed viewers.
  # Merges with the inode/directory pin owned by nautilus.nix.
  xdg.mimeApps = {
    enable = true;
    defaultApplications = {
      "image/jpeg" = [ "org.gnome.Loupe.desktop" ];
      "image/png" = [ "org.gnome.Loupe.desktop" ];
      "image/webp" = [ "org.gnome.Loupe.desktop" ];
      "image/gif" = [ "org.gnome.Loupe.desktop" ];
      "image/bmp" = [ "org.gnome.Loupe.desktop" ];
      "image/tiff" = [ "org.gnome.Loupe.desktop" ];
      "image/avif" = [ "org.gnome.Loupe.desktop" ];
      "image/heic" = [ "org.gnome.Loupe.desktop" ];
      "image/svg+xml" = [ "org.gnome.Loupe.desktop" ];

      "application/pdf" = [ "org.pwmt.zathura.desktop" ];
      "application/epub+zip" = [ "org.pwmt.zathura.desktop" ];

      "application/zip" = [ "org.gnome.FileRoller.desktop" ];
      "application/x-7z-compressed" = [ "org.gnome.FileRoller.desktop" ];
      "application/x-rar-compressed" = [ "org.gnome.FileRoller.desktop" ];
      "application/x-tar" = [ "org.gnome.FileRoller.desktop" ];
      "application/x-compressed-tar" = [ "org.gnome.FileRoller.desktop" ];
      "application/x-bzip2" = [ "org.gnome.FileRoller.desktop" ];
      "application/x-bzip-compressed-tar" = [ "org.gnome.FileRoller.desktop" ];
      "application/gzip" = [ "org.gnome.FileRoller.desktop" ];
      "application/x-gzip" = [ "org.gnome.FileRoller.desktop" ];
      "application/x-xz" = [ "org.gnome.FileRoller.desktop" ];
      "application/x-xz-compressed-tar" = [ "org.gnome.FileRoller.desktop" ];
      "application/zstd" = [ "org.gnome.FileRoller.desktop" ];
      "application/x-zstd-compressed-tar" = [ "org.gnome.FileRoller.desktop" ];

      "text/plain" = [ "org.gnome.TextEditor.desktop" ];
    };
  };
}
