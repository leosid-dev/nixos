# overlays/core.nix — Global overlays applied to every host.
#
# Provides `pkgs.unstable.*` namespace so any module can pull a
# specific package from unstable without additional plumbing.
[
  # Expose the unstable channel as pkgs.unstable
  # (injected via channels.nix — this overlay is a no-op sentinel;
  #  the actual unstable attr is set by channels.nix's `stable // { inherit unstable; }`)
]
