# overlays/core.nix — Global overlays applied to every host.
#
# Pure extension point: append overlay functions to this list to modify the
# package sets built by lib/channels.nix. The `pkgs.unstable` namespace is
# injected by channels.nix itself (via a real overlay), not here.
[ ]
