# modules/home/editor.nix — Declarative Neovim configuration.
{ config, lib, pkgs, ... }:
let
  cfg = config.aspects.home.editor;
in
{
  options.aspects.home.editor = {
    enable = lib.mkEnableOption "Neovim editor";

    neovim = {
      enableLSP = lib.mkOption { type = lib.types.bool; default = true; };
      colorscheme = lib.mkOption { type = lib.types.str; default = "tokyonight"; };
      leader = lib.mkOption { type = lib.types.str; default = " "; };
    };
  };

  config = lib.mkIf cfg.enable {
    programs.neovim = {
      enable = true;
      defaultEditor = true;
      viAlias = true;
      vimAlias = true;

      extraPackages = with pkgs; [ nixd nixfmt-rfc-style ];

      # Keep plugins in the Nix closure. Neovim must not clone mutable state
      # into $XDG_DATA_HOME during startup.
      plugins = with pkgs.vimPlugins; [
        nvim-lspconfig
        telescope-nvim
        tokyonight-nvim
      ];

      extraLuaConfig = ''
        vim.g.mapleader = ${builtins.toJSON cfg.neovim.leader}
        vim.g.maplocalleader = vim.g.mapleader

        vim.opt.termguicolors = true
        vim.opt.number = true
        vim.opt.relativenumber = true
        vim.opt.expandtab = true
        vim.opt.shiftwidth = 2
        vim.opt.tabstop = 2
        vim.opt.updatetime = 300
        vim.opt.completeopt = { "menu", "menuone", "noselect" }
        vim.opt.clipboard = "unnamedplus"

        local map = vim.keymap.set
        map("n", "<leader>ff", "<cmd>Telescope find_files<cr>")
        map("n", "<leader>fg", "<cmd>Telescope live_grep<cr>")
        map("n", "<leader>fb", "<cmd>Telescope buffers<cr>")
        map("n", "<leader>fs", "<cmd>Telescope lsp_document_symbols<cr>")

        ${lib.optionalString cfg.neovim.enableLSP ''
          local lspconfig = require("lspconfig")
          lspconfig.nixd.setup({})
          map("n", "<leader>r", vim.lsp.buf.rename)
          map("n", "<leader>f", function()
            vim.lsp.buf.format({ async = true })
          end)
        ''}

        local colorscheme = ${builtins.toJSON cfg.neovim.colorscheme}
        pcall(vim.cmd, "colorscheme " .. colorscheme)
      '';
    };
  };
}
