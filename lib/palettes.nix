# lib/palettes.nix — Canonical palette definitions.
#
# Pure data: accent -> mode -> palette record.
# Single source of truth for color tokens across the entire desktop:
# - Noctalia custom palette JSON (format-2 snake_case roles + terminal)
# - Kitty terminal colors (foreground/background/cursor/selection/palette)
# - Niri focus ring (active, inactive, workspace background)
# - noctalia-greeter [appearance.palette] (greeter schema still uses the
#   material spellings surface_variant/outline; login.nix maps them)
#
# Schema follows Noctalia's palette-file format 2 (v5.4.x): the 16 palette
# roles include hover/on_hover, which v5.0.1 derived at runtime
# (hover = tertiary). The runtime no longer derives them for fixed palettes
# (since v5.2.1 they fall back to transparent black when omitted), so every
# record ships them explicitly, carrying the old derived values.
{
  monochrome = {
    dark = {
      # Noctalia format-2 palette roles. mSurfaceVariant -> surface_container
      # and mOutline -> outline_variant (v5.4.0 rename, same colors);
      # outline_variant is >= 3:1 against the surface so Noctalia's
      # ensureContrast leaves the derived outline alone.
      primary = "#e6e6e6";
      on_primary = "#000000";
      secondary = "#c4c4c4";
      on_secondary = "#000000";
      tertiary = "#262626";
      on_tertiary = "#e6e6e6";
      # Error is the brightest achromatic step so destructive states stay
      # distinguishable from primary without introducing hue.
      error = "#f5f5f5";
      on_error = "#000000";
      surface = "#000000";
      on_surface = "#e6e6e6";
      surface_container = "#141414";
      on_surface_variant = "#a3a3a3";
      outline_variant = "#5c5c5c";
      shadow = "#000000";
      # Explicit hover fill: the v5.0.1 runtime mapping (hover = tertiary),
      # now carried by the record instead of being derived.
      hover = "#262626";
      on_hover = "#e6e6e6";

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
        cursor_text = "#000000";
        selection_fg = "#000000";
        selection_bg = "#a3a3a3";
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

      opacity = 1.0;
    };
    light = {
      # Hover sits near the surface ladder, with dark on-colour for
      # legibility on it.
      primary = "#1a1a1a";
      on_primary = "#ffffff";
      secondary = "#525252";
      on_secondary = "#ffffff";
      tertiary = "#e4e4e4";
      on_tertiary = "#1a1a1a";
      # Darkest achromatic step mirrors the dark-mode "extreme neutral"
      # convention instead of breaking monochrome with red.
      error = "#0a0a0a";
      on_error = "#ffffff";
      surface = "#ffffff";
      on_surface = "#1a1a1a";
      surface_container = "#f0f0f0";
      on_surface_variant = "#525252";
      # >= 3:1 against the surface so ensureContrast keeps it stable.
      outline_variant = "#949494";
      shadow = "#e0e0e0";
      hover = "#e4e4e4";
      on_hover = "#1a1a1a";

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
        cursor_text = "#ffffff";
        selection_fg = "#ffffff";
        selection_bg = "#525252";
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

      opacity = 1.0;
    };
  };

  catppuccin-mocha = {
    dark = {
      primary = "#89b4fa";
      on_primary = "#11111b";
      secondary = "#b4befe";
      on_secondary = "#11111b";
      tertiary = "#f5c2e7";
      on_tertiary = "#11111b";
      error = "#f38ba8";
      on_error = "#11111b";
      surface = "#1e1e2e";
      on_surface = "#cdd6f4";
      surface_container = "#313244";
      on_surface_variant = "#a6adc8";
      outline_variant = "#45475a";
      shadow = "#11111b";
      hover = "#f5c2e7";
      on_hover = "#11111b";

      focus = {
        active = "#89b4fa";
        inactive = "#45475a";
        background = "#1e1e2e";
      };

      terminal = {
        foreground = "#cdd6f4";
        background = "#1e1e2e";
        cursor = "#f5e0dc";
        cursor_text = "#1e1e2e";
        selection_fg = "#1e1e2e";
        selection_bg = "#f5e0dc";
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

      opacity = 0.95;
    };
    light = {
      primary = "#1e66f5";
      on_primary = "#ffffff";
      secondary = "#7287fd";
      on_secondary = "#ffffff";
      tertiary = "#ea76cb";
      on_tertiary = "#ffffff";
      error = "#d20f39";
      on_error = "#ffffff";
      surface = "#eff1f5";
      on_surface = "#4c4f69";
      surface_container = "#e6e9ef";
      on_surface_variant = "#6c6f85";
      outline_variant = "#9ca0b0";
      shadow = "#bcc0cc";
      hover = "#ea76cb";
      on_hover = "#ffffff";

      focus = {
        active = "#1e66f5";
        inactive = "#9ca0b0";
        background = "#eff1f5";
      };

      terminal = {
        foreground = "#4c4f69";
        background = "#eff1f5";
        cursor = "#dc8a78";
        cursor_text = "#eff1f5";
        selection_fg = "#eff1f5";
        selection_bg = "#dc8a78";
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

      opacity = 0.95;
    };
  };

  adwaita = {
    dark = {
      primary = "#78aeed";
      on_primary = "#1e1e1e";
      secondary = "#62a0ea";
      on_secondary = "#1e1e1e";
      tertiary = "#99c1f1";
      on_tertiary = "#1e1e1e";
      error = "#ed333b";
      on_error = "#ffffff";
      surface = "#1e1e1e";
      on_surface = "#f2f2f2";
      surface_container = "#2d2d2d";
      on_surface_variant = "#c0bfbc";
      outline_variant = "#4d4d4d";
      shadow = "#121212";
      hover = "#99c1f1";
      on_hover = "#1e1e1e";

      focus = {
        active = "#78aeed";
        inactive = "#4d4d4d";
        background = "#1e1e1e";
      };

      terminal = {
        foreground = "#f2f2f2";
        background = "#1e1e1e";
        cursor = "#ffffff";
        cursor_text = "#1e1e1e";
        selection_fg = "#ffffff";
        selection_bg = "#3584e4";
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

      opacity = 0.95;
    };
    light = {
      primary = "#1c71d8";
      on_primary = "#ffffff";
      secondary = "#3584e4";
      on_secondary = "#ffffff";
      tertiary = "#1a5fb4";
      on_tertiary = "#ffffff";
      error = "#c01c28";
      on_error = "#ffffff";
      surface = "#fafafa";
      on_surface = "#241f31";
      surface_container = "#ebebeb";
      on_surface_variant = "#5e5c64";
      outline_variant = "#c0bfbc";
      shadow = "#deddda";
      hover = "#1a5fb4";
      on_hover = "#ffffff";

      focus = {
        active = "#1c71d8";
        inactive = "#c0bfbc";
        background = "#fafafa";
      };

      terminal = {
        foreground = "#241f31";
        background = "#fafafa";
        cursor = "#241f31";
        cursor_text = "#fafafa";
        selection_fg = "#ffffff";
        selection_bg = "#1c71d8";
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

      opacity = 0.95;
    };
  };
}
