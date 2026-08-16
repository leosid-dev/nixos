# modules/home/editor.nix — Neovim via nixvim (fully declarative).
#
# Always-on (editor choice is profile-level). All plugins come from nixpkgs —
# no runtime plugin managers, no downloads. EDITOR/VISUAL are set by nixvim's
# `defaultEditor` (single source of truth, AGENTS.md rule 8).
#
# The colorscheme follows `aspects.theme.accent` (declared by theme.nix):
# monochrome → mini-base16 (derived from canonical palette),
# catppuccin-mocha → catppuccin, adwaita → tokyonight.
{ config, lib, nixvim, ... }:
let
  accent = config.aspects.theme.accent;
  useMonochrome = accent == "monochrome";
  useCatppuccin = accent == "catppuccin-mocha";
  useTokyonight = accent == "adwaita";
  palette = config.aspects.theme.palette;
in
{
  imports = [ nixvim.homeModules.nixvim ];

  config = {
    programs.nixvim = {
      enable = true;
      defaultEditor = true;
      viAlias = true;
      vimAlias = true;

      # nixvim pins its own nixpkgs; the flake input `follows` overrides that
      # pin. Nixvim asks us to make the override explicit, so it is.
      nixpkgs.source = nixvim.inputs.nixpkgs.outPath;

      globals.mapleader = " ";

      opts = {
        termguicolors = true;
        number = true;
        relativenumber = true;
        expandtab = true;
        shiftwidth = 2;
        tabstop = 2;
        updatetime = 300;
        completeopt = "menu,menuone,noselect";
      };

      clipboard.register = "unnamedplus";

      colorschemes = {
        catppuccin = {
          enable = useCatppuccin;
          settings.flavour = "mocha";
        };
        tokyonight.enable = useTokyonight;
        mini-base16 = {
          enable = useMonochrome;
          settings.palette = palette.base16;
        };
      };

      plugins = {
        lsp = {
          enable = true;
          servers.nixd.enable = true;
        };
        treesitter.enable = true;
        telescope.enable = true;
        cmp.enable = true;
        which-key.enable = true;
        gitsigns.enable = true;
        web-devicons.enable = true;
      };

      keymaps = [
        { key = "<leader>ff"; action = "<cmd>Telescope find_files<cr>"; }
        { key = "<leader>fg"; action = "<cmd>Telescope live_grep<cr>"; }
        { key = "<leader>fb"; action = "<cmd>Telescope buffers<cr>"; }
        { key = "<leader>fs"; action = "<cmd>Telescope lsp_document_symbols<cr>"; }
      ];
    };
  };
}
