# modules/home/editor.nix — Neovim file editor configuration with sensible defaults.
{ config, lib, pkgs, ... }:
let
  cfg = config.aspects.home.editor;
  themeAccent = config.aspects.theme.accent or "adwaita";
  defaultColorscheme = if themeAccent == "catppuccin-mocha" then "catppuccin" else "tokyonight";
in
{
  options.aspects.home.editor = {
    default = lib.mkOption {
      type = lib.types.enum [ "neovim" "vscode" "emacs" ];
      default = "neovim";
    };

    neovim = {
      enableLSP = lib.mkOption { type = lib.types.bool; default = true; };
      colorscheme = lib.mkOption { type = lib.types.str; default = defaultColorscheme; };
      leader = lib.mkOption { type = lib.types.str; default = " "; };
    };
  };

  # Provide a minimal init.lua + rc.lua to bootstrap lazy.nvim and a small plugin set.
  config = lib.mkIf (cfg.default == "neovim") {
    programs.neovim = {
      enable = true;
      defaultEditor = true;
      viAlias = true;
      vimAlias = true;

      extraPackages = with pkgs; [ nixd nixfmt-rfc-style ];

      # Keep the built-in extraConfig minimal; place the main config under xdg.configFile.
      extraConfig = ''
See xdg.configFile for the full init.lua bootstrap
'';
    };

    xdg.configFile."nvim/init.lua".text = ''
-- Minimal bootstrap for lazy.nvim and site config
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({"git", "clone", "--filter=blob:none", "https://github.com/folke/lazy.nvim", lazypath})
end
vim.opt.rtp:prepend(lazypath)
require('rc')
'';

    xdg.configFile."nvim/lua/rc.lua".text = ''
-- Minimal site rc.lua
local M = {}
-- basic options
vim.o.termguicolors = true
vim.o.number = true
vim.o.relativenumber = true
vim.o.expandtab = true
vim.o.shiftwidth = 2
vim.o.tabstop = 2
vim.o.updatetime = 300
vim.o.completeopt = "menu,menuone,noselect"
vim.o.clipboard = "unnamedplus"

-- leader
vim.g.mapleader = " "
local map = vim.keymap.set

-- lazy.nvim plugins
require('lazy').setup({
  { 'neovim/nvim-lspconfig' },
  { 'williamboman/mason.nvim', build = function() require('mason').setup() end },
  { 'williamboman/mason-lspconfig.nvim' },
  { 'jose-elias-alvarez/null-ls.nvim' },
  { 'hrsh7th/nvim-cmp' },
  { 'nvim-treesitter/nvim-treesitter', run = ':TSUpdate' },
  { 'nvim-telescope/telescope.nvim' },
  { 'folke/which-key.nvim' },
  { 'lewis6991/gitsigns.nvim' },
})

-- mason ensure installed (best-effort)
pcall(function()
  local ok, mason = pcall(require, 'mason')
  if ok and mason then
    require('mason').setup()
    pcall(function()
      require('mason-lspconfig').setup({ ensure_installed = { 'lua-language-server', 'pyright', 'rust-analyzer', 'bash-language-server', 'marksman', 'json-lsp' } })
    end)
  end
end)

-- keymaps
map('n', '<leader>ff', '<cmd>Telescope find_files<cr>')
map('n', '<leader>fg', '<cmd>Telescope live_grep<cr>')
map('n', '<leader>fb', '<cmd>Telescope buffers<cr>')
map('n', '<leader>fs', '<cmd>Telescope lsp_document_symbols<cr>')
map('n', '<leader>r', vim.lsp.buf.rename)
map('n', '<leader>f', function() vim.lsp.buf.format { async = true } end)

-- colorscheme selection (from aspects.theme.accent)
local cs = "${toString cfg.neovim.colorscheme}"
pcall(function() vim.cmd('colorscheme ' .. cs) end)

return M
'';
  };
}
