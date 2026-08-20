# lib/palettes.nix — Canonical palette definitions.
#
# Pure data: accent -> mode -> palette record.
# Single source of truth for color tokens across the entire desktop:
# - Noctalia custom palette JSON (m* Material roles + terminal)
# - Kitty terminal colors (foreground/background/cursor/selection/palette)
# - Niri focus ring (active, inactive, workspace background)
# - Neovim mini-base16 (base00..base0F grayscale ramp for monochrome)
{
  monochrome = {
    dark = {
      # Material roles for Noctalia v5 (m* schema).
      # The runtime maps hover = tertiary (mapGeneratedPaletteMode), so
      # mTertiary doubles as the hover fill; mOutline is chosen >= 3:1
      # against the surface so Noctalia's ensureContrast leaves it alone.
      mPrimary = "#e6e6e6";
      mOnPrimary = "#000000";
      mSecondary = "#c4c4c4";
      mOnSecondary = "#000000";
      mTertiary = "#262626";
      mOnTertiary = "#e6e6e6";
      # Error is the brightest achromatic step so destructive states stay
      # distinguishable from primary without introducing hue.
      mError = "#f5f5f5";
      mOnError = "#000000";
      mSurface = "#000000";
      mOnSurface = "#e6e6e6";
      mSurfaceVariant = "#141414";
      mOnSurfaceVariant = "#a3a3a3";
      mOutline = "#5c5c5c";
      mShadow = "#000000";

      # Focus ring for Niri
      focus = {
        active = "#e6e6e6";
        inactive = "#3d3d3d";
        background = "#000000";
      };

      # Terminal colors for Kitty + Noctalia. ANSI ladders are strictly
      # monotonic: every bright value outshines its normal counterpart.
      terminal = {
        foreground = "#e6e6e6";
        background = "#000000";
        cursor = "#e6e6e6";
        cursorText = "#000000";
        selectionFg = "#000000";
        selectionBg = "#a3a3a3";
        normal = {
          black = "#1a1a1a";
          red = "#8c8c8c";
          green = "#959595";
          yellow = "#9e9e9e";
          blue = "#a7a7a7";
          magenta = "#b0b0b0";
          cyan = "#b9b9b9";
          white = "#e6e6e6";
        };
        bright = {
          black = "#5c5c5c";
          red = "#a9a9a9";
          green = "#b2b2b2";
          yellow = "#bbbbbb";
          blue = "#c4c4c4";
          magenta = "#cdcdcd";
          cyan = "#d6d6d6";
          white = "#f5f5f5";
        };
      };

      # Base16 scale for Neovim (mini-base16)
      base16 = {
        base00 = "#000000";
        base01 = "#141414";
        base02 = "#262626";
        base03 = "#3d3d3d";
        base04 = "#8c8c8c";
        base05 = "#b3b3b3";
        base06 = "#d6d6d6";
        base07 = "#f5f5f5";
        base08 = "#e0e0e0";
        base09 = "#d0d0d0";
        base0A = "#c4c4c4";
        base0B = "#b8b8b8";
        base0C = "#acacac";
        base0D = "#a0a0a0";
        base0E = "#949494";
        base0F = "#888888";
      };

      opacity = 1.0;
    };
    light = {
      # mTertiary doubles as the hover fill at runtime — kept near the
      # surface ladder, with dark on-colour for legibility on it.
      mPrimary = "#1a1a1a";
      mOnPrimary = "#ffffff";
      mSecondary = "#525252";
      mOnSecondary = "#ffffff";
      mTertiary = "#e4e4e4";
      mOnTertiary = "#1a1a1a";
      # Darkest achromatic step mirrors the dark-mode "extreme neutral"
      # convention instead of breaking monochrome with red.
      mError = "#0a0a0a";
      mOnError = "#ffffff";
      mSurface = "#ffffff";
      mOnSurface = "#1a1a1a";
      mSurfaceVariant = "#f0f0f0";
      mOnSurfaceVariant = "#525252";
      # >= 3:1 against the surface so ensureContrast keeps it stable.
      mOutline = "#949494";
      mShadow = "#e0e0e0";

      focus = {
        active = "#1a1a1a";
        inactive = "#c4c4c4";
        background = "#ffffff";
      };

      # Light-terminal ladder: brighter values recede, darker values carry
      # weight; bright variants emphasise over their normal counterparts.
      terminal = {
        foreground = "#1a1a1a";
        background = "#ffffff";
        cursor = "#1a1a1a";
        cursorText = "#ffffff";
        selectionFg = "#ffffff";
        selectionBg = "#525252";
        normal = {
          black = "#1a1a1a";
          red = "#474747";
          green = "#4e4e4e";
          yellow = "#555555";
          blue = "#5c5c5c";
          magenta = "#636363";
          cyan = "#6a6a6a";
          white = "#7a7a7a";
        };
        bright = {
          black = "#8a8a8a";
          red = "#2e2e2e";
          green = "#353535";
          yellow = "#3c3c3c";
          blue = "#434343";
          magenta = "#4a4a4a";
          cyan = "#515151";
          white = "#0a0a0a";
        };
      };

      base16 = {
        base00 = "#ffffff";
        base01 = "#f0f0f0";
        base02 = "#e0e0e0";
        base03 = "#c4c4c4";
        base04 = "#737373";
        base05 = "#525252";
        base06 = "#2e2e2e";
        base07 = "#1a1a1a";
        base08 = "#686868";
        base09 = "#606060";
        base0A = "#585858";
        base0B = "#505050";
        base0C = "#484848";
        base0D = "#404040";
        base0E = "#383838";
        base0F = "#303030";
      };

      opacity = 1.0;
    };
  };

  catppuccin-mocha = {
    dark = {
      mPrimary = "#89b4fa";
      mOnPrimary = "#11111b";
      mSecondary = "#b4befe";
      mOnSecondary = "#11111b";
      mTertiary = "#f5c2e7";
      mOnTertiary = "#11111b";
      mError = "#f38ba8";
      mOnError = "#11111b";
      mSurface = "#1e1e2e";
      mOnSurface = "#cdd6f4";
      mSurfaceVariant = "#313244";
      mOnSurfaceVariant = "#a6adc8";
      mOutline = "#45475a";
      mShadow = "#11111b";
      mHover = "#45475a";
      mOnHover = "#cdd6f4";

      focus = {
        active = "#89b4fa";
        inactive = "#45475a";
        background = "#1e1e2e";
      };

      terminal = {
        foreground = "#cdd6f4";
        background = "#1e1e2e";
        cursor = "#f5e0dc";
        cursorText = "#1e1e2e";
        selectionFg = "#1e1e2e";
        selectionBg = "#f5e0dc";
        normal = {
          black = "#45475a";
          red = "#f38ba8";
          green = "#a6e3a1";
          yellow = "#f9e2af";
          blue = "#89b4fa";
          magenta = "#f5c2e7";
          cyan = "#94e2d5";
          white = "#bac2de";
        };
        bright = {
          black = "#585b70";
          red = "#f38ba8";
          green = "#a6e3a1";
          yellow = "#f9e2af";
          blue = "#89b4fa";
          magenta = "#f5c2e7";
          cyan = "#94e2d5";
          white = "#a6adc8";
        };
      };

      base16 = null;
      opacity = 0.95;
    };
    light = {
      mPrimary = "#1e66f5";
      mOnPrimary = "#ffffff";
      mSecondary = "#7287fd";
      mOnSecondary = "#ffffff";
      mTertiary = "#ea76cb";
      mOnTertiary = "#ffffff";
      mError = "#d20f39";
      mOnError = "#ffffff";
      mSurface = "#eff1f5";
      mOnSurface = "#4c4f69";
      mSurfaceVariant = "#e6e9ef";
      mOnSurfaceVariant = "#6c6f85";
      mOutline = "#9ca0b0";
      mShadow = "#bcc0cc";
      mHover = "#ccd0da";
      mOnHover = "#4c4f69";

      focus = {
        active = "#1e66f5";
        inactive = "#9ca0b0";
        background = "#eff1f5";
      };

      terminal = {
        foreground = "#4c4f69";
        background = "#eff1f5";
        cursor = "#dc8a78";
        cursorText = "#eff1f5";
        selectionFg = "#eff1f5";
        selectionBg = "#dc8a78";
        normal = {
          black = "#5c5f77";
          red = "#d20f39";
          green = "#40a02b";
          yellow = "#df8e1d";
          blue = "#1e66f5";
          magenta = "#ea76cb";
          cyan = "#179299";
          white = "#acb0be";
        };
        bright = {
          black = "#6c6f85";
          red = "#d20f39";
          green = "#40a02b";
          yellow = "#df8e1d";
          blue = "#1e66f5";
          magenta = "#ea76cb";
          cyan = "#179299";
          white = "#bcc0cc";
        };
      };

      base16 = null;
      opacity = 0.95;
    };
  };

  adwaita = {
    dark = {
      mPrimary = "#78aeed";
      mOnPrimary = "#1e1e1e";
      mSecondary = "#62a0ea";
      mOnSecondary = "#1e1e1e";
      mTertiary = "#99c1f1";
      mOnTertiary = "#1e1e1e";
      mError = "#ed333b";
      mOnError = "#ffffff";
      mSurface = "#1e1e1e";
      mOnSurface = "#f2f2f2";
      mSurfaceVariant = "#2d2d2d";
      mOnSurfaceVariant = "#c0bfbc";
      mOutline = "#4d4d4d";
      mShadow = "#121212";
      mHover = "#383838";
      mOnHover = "#f2f2f2";

      focus = {
        active = "#78aeed";
        inactive = "#4d4d4d";
        background = "#1e1e1e";
      };

      terminal = {
        foreground = "#f2f2f2";
        background = "#1e1e1e";
        cursor = "#ffffff";
        cursorText = "#1e1e1e";
        selectionFg = "#ffffff";
        selectionBg = "#3584e4";
        normal = {
          black = "#1e1e1e";
          red = "#ed333b";
          green = "#57e389";
          yellow = "#f6d32d";
          blue = "#62a0ea";
          magenta = "#c061cb";
          cyan = "#4cd9c0";
          white = "#f2f2f2";
        };
        bright = {
          black = "#4d4d4d";
          red = "#f66151";
          green = "#8ff0a4";
          yellow = "#f9f06b";
          blue = "#99c1f1";
          magenta = "#dc8add";
          cyan = "#6de5da";
          white = "#ffffff";
        };
      };

      base16 = null;
      opacity = 0.95;
    };
    light = {
      mPrimary = "#1c71d8";
      mOnPrimary = "#ffffff";
      mSecondary = "#3584e4";
      mOnSecondary = "#ffffff";
      mTertiary = "#1a5fb4";
      mOnTertiary = "#ffffff";
      mError = "#c01c28";
      mOnError = "#ffffff";
      mSurface = "#fafafa";
      mOnSurface = "#241f31";
      mSurfaceVariant = "#ebebeb";
      mOnSurfaceVariant = "#5e5c64";
      mOutline = "#c0bfbc";
      mShadow = "#deddda";
      mHover = "#deddda";
      mOnHover = "#241f31";

      focus = {
        active = "#1c71d8";
        inactive = "#c0bfbc";
        background = "#fafafa";
      };

      terminal = {
        foreground = "#241f31";
        background = "#fafafa";
        cursor = "#241f31";
        cursorText = "#fafafa";
        selectionFg = "#ffffff";
        selectionBg = "#1c71d8";
        normal = {
          black = "#241f31";
          red = "#c01c28";
          green = "#26a269";
          yellow = "#a2734c";
          blue = "#1a5fb4";
          magenta = "#a347ba";
          cyan = "#2aa1b3";
          white = "#deddda";
        };
        bright = {
          black = "#5e5c64";
          red = "#e01b24";
          green = "#33d17a";
          yellow = "#e5a50a";
          blue = "#3584e4";
          magenta = "#c061cb";
          cyan = "#33c7de";
          white = "#ffffff";
        };
      };

      base16 = null;
      opacity = 0.95;
    };
  };
}
