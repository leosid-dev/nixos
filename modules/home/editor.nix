# modules/home/editor.nix — Neovim file editor configuration with sensible defaults.
#
# `EDITOR=nvim` is set globally via programs.neovim.defaultEditor, so other
# modules must NOT redefine it. ripgrep/fd come from the system core
# package set (modules/system/core/packages.nix); no duplication here.
{ pkgs, ... }:
{
  programs.neovim = {
    enable = true;
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;

    extraPackages = with pkgs; [
      # Language Servers / Tools for Nix & general development
      nixd # Nix LSP
      nixfmt-rfc-style # Nix formatter
    ];

    extraConfig = ''
      set number
      set relativenumber
      set expandtab
      set shiftwidth=2
      set tabstop=2
      set smartindent
      set termguicolors
      set ignorecase
      set smartcase
      set cursorline
      set scrolloff=8
      set clipboard=unnamedplus
    '';
  };
}
