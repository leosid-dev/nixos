# modules/home/editor.nix — Neovim via nixvim (fully declarative IDE).
#
# Always-on (editor choice is profile-level). All plugins, formatters, and
# language servers come from nixpkgs — no runtime plugin managers, no downloads.
# EDITOR/VISUAL are set by nixvim's `defaultEditor` (single source of truth).
#
# Configured as a feature-rich, modern IDE styled with the TokyoNight theme.
{ pkgs, nixvim, ... }:
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

      globals = {
        mapleader = " ";
        maplocalleader = " ";
      };

      opts = {
        # Visual & line numbers
        termguicolors = true;
        number = true;
        relativenumber = true;
        cursorline = true;
        signcolumn = "yes";
        wrap = false;
        scrolloff = 8;
        sidescrolloff = 8;

        # Indentation (2 spaces default, matches nixos project style)
        expandtab = true;
        shiftwidth = 2;
        tabstop = 2;
        softtabstop = 2;
        autoindent = true;
        smartindent = true;

        # Search behavior
        ignorecase = true;
        smartcase = true;
        incsearch = true;
        hlsearch = true;

        # Undo & backup (persistent undo, no noisy swap files)
        undofile = true;
        undolevels = 10000;
        swapfile = false;
        backup = false;
        writebackup = false;

        # Splits & UI
        splitbelow = true;
        splitright = true;
        timeoutlen = 300;
        updatetime = 200;
        completeopt = "menu,menuone,noselect";
        pumheight = 10;
        mouse = "a";
        showmode = false; # Handled by statusline
      };

      clipboard.register = "unnamedplus";

      # TokyoNight colorscheme
      colorschemes.tokyonight = {
        enable = true;
        settings = {
          style = "night";
          transparent = false;
          terminal_colors = true;
          styles = {
            comments.italic = true;
            keywords.italic = true;
            functions = { };
            variables = { };
          };
        };
      };

      # Formatters, tools & search helpers installed in Neovim's PATH
      extraPackages = with pkgs; [
        ripgrep
        fd
        nixfmt
        stylua
        shfmt
        prettierd
      ];

      plugins = {
        # UI & Icons
        web-devicons.enable = true;
        which-key = {
          enable = true;
          settings = {
            spec = [
              { __unkeyed-1 = "<leader>b"; group = "Buffers"; }
              { __unkeyed-1 = "<leader>c"; group = "Code / LSP"; }
              { __unkeyed-1 = "<leader>f"; group = "Find (Telescope)"; }
              { __unkeyed-1 = "<leader>g"; group = "Git"; }
              { __unkeyed-1 = "<leader>t"; group = "Terminal"; }
              { __unkeyed-1 = "<leader>w"; group = "Window splits"; }
              { __unkeyed-1 = "<leader>x"; group = "Diagnostics / Trouble"; }
            ];
          };
        };

        # Statusline & Bufferline
        lualine = {
          enable = true;
          settings = {
            options = {
              theme = "tokyonight";
              globalstatus = true;
              icons_enabled = true;
              component_separators = { left = "│"; right = "│"; };
              section_separators = { left = ""; right = ""; };
            };
            sections = {
              lualine_a = [ "mode" ];
              lualine_b = [ "branch" "diff" "diagnostics" ];
              lualine_c = [
                {
                  __unkeyed-1 = "filename";
                  path = 1; # Relative path
                }
              ];
              lualine_x = [ "filetype" ];
              lualine_y = [ "progress" ];
              lualine_z = [ "location" ];
            };
          };
        };

        bufferline = {
          enable = true;
          settings = {
            options = {
              mode = "buffers";
              diagnostics = "nvim_lsp";
              separator_style = "thin";
              offsets = [
                {
                  filetype = "neo-tree";
                  text = "File Explorer";
                  highlight = "Directory";
                  text_align = "left";
                }
              ];
            };
          };
        };

        # File Tree & Navigation
        neo-tree = {
          enable = true;
          settings = {
            enable_git_status = true;
            enable_diagnostics = true;
            filesystem = {
              follow_current_file = {
                enabled = true;
              };
              filtered_items = {
                visible = true;
                hide_dotfiles = false;
                hide_gitignored = false;
              };
            };
          };
        };

        # Code Intelligence & Syntax
        treesitter = {
          enable = true;
          settings = {
            highlight.enable = true;
            indent.enable = true;
          };
        };
        treesitter-context.enable = true;
        ts-autotag.enable = true;

        # Mini suite: high-performance editing modules (indent guides, pairs, surround, comments, textobjects, cursor word highlight)
        mini = {
          enable = true;
          modules = {
            indentscope = {
              symbol = "│";
              options = { try_as_border = true; };
            };
            cursorword = { };
            pairs = { };
            surround = { };
            comment = { };
            ai = { };
            bufremove = { };
          };
        };

        # Fuzzy Finder
        telescope = {
          enable = true;
          extensions = {
            fzf-native.enable = true;
          };
          settings = {
            defaults = {
              layout_config = {
                horizontal = {
                  prompt_position = "top";
                };
              };
              sorting_strategy = "ascending";
            };
          };
        };

        # Git Integration
        gitsigns = {
          enable = true;
          settings = {
            current_line_blame = true;
            current_line_blame_opts = {
              delay = 400;
              virt_text_pos = "eol";
            };
          };
        };

        # Terminal
        toggleterm = {
          enable = true;
          settings = {
            open_mapping = "[[<C-\\>]]";
            direction = "float";
            float_opts = {
              border = "curved";
            };
          };
        };

        # LSP, Diagnostics & Notifications
        fidget.enable = true;
        trouble.enable = true;

        lsp = {
          enable = true;
          servers = {
            # Nix
            nixd.enable = true;
            # Lua
            lua_ls.enable = true;
            # Shell
            bashls.enable = true;
            # Web & configs
            jsonls.enable = true;
            yamlls.enable = true;
            marksman.enable = true;
            taplo.enable = true;
            ts_ls.enable = true;
            # Python
            pyright.enable = true;
            ruff.enable = true;
            # Systems
            clangd.enable = true;
            rust_analyzer = {
              enable = true;
              installCargo = false;
              installRustc = false;
            };
          };

          keymaps = {
            diagnostic = {
              "<leader>cd" = "open_float";
              "[d" = "goto_prev";
              "]d" = "goto_next";
            };
            lspBuf = {
              "K" = "hover";
              "gD" = "declaration";
              "gd" = "definition";
              "gi" = "implementation";
              "gt" = "type_definition";
              "gr" = "references";
              "<leader>ca" = "code_action";
              "<leader>cr" = "rename";
              "<leader>cf" = "format";
            };
          };
        };

        # Code Formatting
        conform-nvim = {
          enable = true;
          settings = {
            formatters_by_ft = {
              nix = [ "nixfmt" ];
              lua = [ "stylua" ];
              python = [ "ruff_format" ];
              javascript = [ "prettierd" "prettier" ];
              typescript = [ "prettierd" "prettier" ];
              json = [ "prettierd" "prettier" ];
              yaml = [ "prettierd" "prettier" ];
              markdown = [ "prettierd" "prettier" ];
              bash = [ "shfmt" ];
              sh = [ "shfmt" ];
            };
            format_on_save = {
              lsp_format = "fallback";
              timeout_ms = 1000;
            };
          };
        };

        # Autocompletion & Snippets
        luasnip.enable = true;
        lspkind = {
          enable = true;
          cmp.enable = true;
        };

        cmp-nvim-lsp.enable = true;
        cmp-buffer.enable = true;
        cmp-path.enable = true;
        cmp_luasnip.enable = true;

        cmp = {
          enable = true;
          autoEnableSources = true;
          settings = {
            snippet.expand = "function(args) require('luasnip').lsp_expand(args.body) end";
            sources = [
              { name = "nvim_lsp"; }
              { name = "luasnip"; }
              { name = "path"; }
              { name = "buffer"; }
            ];
            mapping = {
              "<C-Space>" = "cmp.mapping.complete()";
              "<C-d>" = "cmp.mapping.scroll_docs(-4)";
              "<C-f>" = "cmp.mapping.scroll_docs(4)";
              "<C-e>" = "cmp.mapping.close()";
              "<CR>" = "cmp.mapping.confirm({ select = true })";
              "<Tab>" = "cmp.mapping(function(fallback) if cmp.visible() then cmp.select_next_item() elseif require('luasnip').expand_or_jumpable() then require('luasnip').expand_or_jump() else fallback() end end, { 'i', 's' })";
              "<S-Tab>" = "cmp.mapping(function(fallback) if cmp.visible() then cmp.select_prev_item() elseif require('luasnip').jumpable(-1) then require('luasnip').jump(-1) else fallback() end end, { 'i', 's' })";
            };
            window = {
              completion.border = "rounded";
              documentation.border = "rounded";
            };
          };
        };
      };

      keymaps = [
        # Window navigation
        { key = "<C-h>"; action = "<C-w>h"; mode = "n"; }
        { key = "<C-j>"; action = "<C-w>j"; mode = "n"; }
        { key = "<C-k>"; action = "<C-w>k"; mode = "n"; }
        { key = "<C-l>"; action = "<C-w>l"; mode = "n"; }

        # Window splits
        { key = "<leader>wv"; action = "<cmd>vsplit<cr>"; mode = "n"; }
        { key = "<leader>ws"; action = "<cmd>split<cr>"; mode = "n"; }
        { key = "<leader>wd"; action = "<cmd>close<cr>"; mode = "n"; }

        # Clear search highlight
        { key = "<Esc>"; action = "<cmd>nohlsearch<cr><Esc>"; mode = "n"; }

        # Move selected lines up/down in visual mode
        { key = "J"; action = ":m '>+1<CR>gv=gv"; mode = "v"; }
        { key = "K"; action = ":m '<-2<CR>gv=gv"; mode = "v"; }

        # Keep cursor centered during scrolls & search repeats
        { key = "<C-d>"; action = "<C-d>zz"; mode = "n"; }
        { key = "<C-u>"; action = "<C-u>zz"; mode = "n"; }
        { key = "n"; action = "nzzzv"; mode = "n"; }
        { key = "N"; action = "Nzzzv"; mode = "n"; }

        # Buffer navigation & management
        { key = "<S-l>"; action = "<cmd>BufferLineCycleNext<cr>"; mode = "n"; }
        { key = "<S-h>"; action = "<cmd>BufferLineCyclePrev<cr>"; mode = "n"; }
        { key = "<leader>bn"; action = "<cmd>BufferLineCycleNext<cr>"; mode = "n"; }
        { key = "<leader>bp"; action = "<cmd>BufferLineCyclePrev<cr>"; mode = "n"; }
        { key = "<leader>bd"; action = "<cmd>lua MiniBufremove.delete()<cr>"; mode = "n"; }

        # File explorer (Neo-tree)
        { key = "<leader>e"; action = "<cmd>Neotree toggle<cr>"; mode = "n"; }
        { key = "<leader>o"; action = "<cmd>Neotree reveal<cr>"; mode = "n"; }

        # Telescope fuzzy finding
        { key = "<leader>ff"; action = "<cmd>Telescope find_files<cr>"; mode = "n"; }
        { key = "<leader>fg"; action = "<cmd>Telescope live_grep<cr>"; mode = "n"; }
        { key = "<leader>fb"; action = "<cmd>Telescope buffers<cr>"; mode = "n"; }
        { key = "<leader>fr"; action = "<cmd>Telescope oldfiles<cr>"; mode = "n"; }
        { key = "<leader>fs"; action = "<cmd>Telescope lsp_document_symbols<cr>"; mode = "n"; }
        { key = "<leader>fS"; action = "<cmd>Telescope lsp_workspace_symbols<cr>"; mode = "n"; }
        { key = "<leader>fd"; action = "<cmd>Telescope diagnostics<cr>"; mode = "n"; }
        { key = "<leader>fh"; action = "<cmd>Telescope help_tags<cr>"; mode = "n"; }
        { key = "<leader>fk"; action = "<cmd>Telescope keymaps<cr>"; mode = "n"; }

        # Trouble diagnostics
        { key = "<leader>xx"; action = "<cmd>Trouble diagnostics toggle<cr>"; mode = "n"; }
        { key = "<leader>xd"; action = "<cmd>Trouble diagnostics toggle filter.buf=0<cr>"; mode = "n"; }
        { key = "<leader>xq"; action = "<cmd>Trouble qflist toggle<cr>"; mode = "n"; }
        { key = "<leader>xl"; action = "<cmd>Trouble loclist toggle<cr>"; mode = "n"; }

        # Git (Gitsigns)
        { key = "<leader>gb"; action = "<cmd>Gitsigns blame_line<cr>"; mode = "n"; }
        { key = "<leader>gp"; action = "<cmd>Gitsigns preview_hunk<cr>"; mode = "n"; }
        { key = "<leader>gh"; action = "<cmd>Gitsigns stage_hunk<cr>"; mode = "n"; }
        { key = "<leader>gu"; action = "<cmd>Gitsigns undo_stage_hunk<cr>"; mode = "n"; }
        { key = "<leader>gr"; action = "<cmd>Gitsigns reset_hunk<cr>"; mode = "n"; }
        { key = "<leader>gd"; action = "<cmd>Gitsigns diffthis<cr>"; mode = "n"; }
        { key = "]h"; action = "<cmd>Gitsigns next_hunk<cr>"; mode = "n"; }
        { key = "[h"; action = "<cmd>Gitsigns prev_hunk<cr>"; mode = "n"; }

        # Terminal
        { key = "<leader>tt"; action = "<cmd>ToggleTerm direction=float<cr>"; mode = "n"; }
        { key = "<leader>th"; action = "<cmd>ToggleTerm direction=horizontal size=15<cr>"; mode = "n"; }
      ];
    };
  };
}
