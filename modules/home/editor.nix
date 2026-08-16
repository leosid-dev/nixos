# modules/home/editor.nix — Neovim via nixvim (fully declarative).
#
# Always-on (editor choice is profile-level). All plugins come from nixpkgs —
# no runtime plugin managers, no downloads. EDITOR/VISUAL are set by nixvim's
# `defaultEditor` (single source of truth, AGENTS.md rule 8).
#
# The colorscheme follows `aspects.theme.accent` (declared by theme.nix):
# monochrome → mini-base16 grayscale, catppuccin-mocha → catppuccin,
# anything else → tokyonight.
{ config, lib, nixvim, ... }:
let
  accent = config.aspects.theme.accent or "adwaita";
  useMonochrome = accent == "monochrome";
  useCatppuccin = accent == "catppuccin-mocha";
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
        tokyonight.enable = !useMonochrome && !useCatppuccin;
        # Grayscale palette: base00 is true black to match the shell theme.
        mini-base16 = {
          enable = useMonochrome;
          settings.palette = {
            base00 = "#000000";
            base01 = "#141414";
            base02 = "#262626";
            base03 = "#3d3d3d";
            base04 = "#8c8c8c";
            base05 = "#b3b3b3";
            base06 = "#d6d6d6";
            base07 = "#f5f5f5";
            base08 = "#e6e6e6";
            base09 = "#c4c4c4";
            base0A = "#bdbdbd";
            base0B = "#adadad";
            base0C = "#a3a3a3";
            base0D = "#999999";
            base0E = "#8c8c8c";
            base0F = "#7a7a7a";
          };
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
