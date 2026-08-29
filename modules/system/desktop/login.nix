# modules/system/desktop/login.nix — Login / greeter service.
#
# Uses Noctalia Greeter (greetd-based) for a login screen matching the
# Noctalia shell. Greeters run pre-login as the `greeter` user, so they are
# inherently a system concern — Home Manager cannot manage them.
#
# The keyboard layout comes from `aspects.locale.keyMap` (declared in
# modules/system/core/locale.nix) so console + login never disagree.
#
# The appearance is declaratively synced with the Noctalia shell: the
# palette is derived from lib/palettes.nix via the system-side accent/mode
# mirror (modules/system/theme.nix), the same canonical color source the
# shell consumes through HM's aspects.theme. A complete [appearance.palette]
# wins over the shell-written sync.toml, so the greeter is deterministic
# from first boot. No wallpaper is declared: the greeter paints from the
# shipped palette, matching the compositor's palette-derived backdrop.
#
# Fingerprint: the greeter starts the greetd/PAM conversation only on
# submit, and pam_fprintd is the first (`sufficient`) module of the greetd
# stack — so an empty-submit allowance is what makes the sensor wake on
# Enter instead of only after a password attempt. With it, Enter on the
# empty field starts PAM, fprintd's "Place finger" info is shown as a
# status hint, and a placed finger logs in. A typed password still works:
# it is armed and auto-posted to the pam_unix `try_first_pass` prompt once
# fprintd fails or times out. pam_unix (`nullok` only matches empty-password
# accounts) + pam_deny close the empty-submit door; the unixAuth fallback
# assertion in modules/system/hardware/fingerprint.nix is unaffected.
{ lib, config, ... }:
let
  # Canonical color tokens (accent -> mode -> palette record).
  palettes = import ../../../lib/palettes.nix;
  theme = config.aspects.theme;
  selected = palettes.${theme.accent}.${theme.mode};

  # greeter.toml [appearance.palette] schema: the 14 Material roles plus
  # hover/on_hover. The Noctalia runtime derives hover = tertiary
  # (see lib/palettes.nix), so the greeter mirrors that mapping.
  greeterPalette = with selected; {
    primary = mPrimary;
    on_primary = mOnPrimary;
    secondary = mSecondary;
    on_secondary = mOnSecondary;
    tertiary = mTertiary;
    on_tertiary = mOnTertiary;
    error = mError;
    on_error = mOnError;
    surface = mSurface;
    on_surface = mOnSurface;
    surface_variant = mSurfaceVariant;
    on_surface_variant = mOnSurfaceVariant;
    outline = mOutline;
    shadow = mShadow;
    hover = mTertiary;
    on_hover = mOnTertiary;
  };
in
{
  config = lib.mkIf config.aspects.desktop.enable {
    programs.noctalia-greeter = {
      enable = true;
      settings = {
        session.default = "niri";
        keyboard.layout = config.aspects.locale.keyMap;
        appearance = {
          # "Synced": palette below (declarative, wins over sync.toml).
          scheme = "Synced";
          theme_mode = theme.mode;
          hide_logo = true;
          # System UI font — pre-login visible via aspects.fonts; aligned
          # with HM's aspects.theme.font by contract (see fonts.nix).
          font_family = config.aspects.fonts.uiFont.name;
          palette = greeterPalette;
        };
        # fprintd wake-on-Enter (see header comment). Off without the
        # fingerprint aspect, keeping empty submits strictly rejected.
        auth.allow_empty_password = config.aspects.hardware.fingerprint.enable;
      };
    };
  };
}
