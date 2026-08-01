# modules/home/editor.nix — Neovim file editor configuration with sensible defaults.
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
      ripgrep
      fd
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
