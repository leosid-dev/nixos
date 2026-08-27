# overlays/core.nix — Global overlays applied to every host.
#
# Pure extension point: append overlay functions to this list to modify the
# package sets built by lib/channels.nix. The `pkgs.unstable` namespace is
# injected by channels.nix itself (via a real overlay), not here.
#
# NOTE: these overlays are applied to BOTH the stable and unstable channels,
# but the `pkgs.unstable` attach overlay lands only on stable. Overlays here
# must therefore never reference `prev.unstable` (use `final` lazily, or
# avoid the reference entirely).
[ ]
