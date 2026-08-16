# Nix Cheatsheet (Flakes, Home Manager, NixOS)

A compact, goal-scoped reference for common Nix commands used with this repository (flakes + Home Manager + NixOS).

## Validation / Quick evaluation
- Evaluate an attribute (fast, non‑mutating):
  - `nix eval .#lib`
  - Goal: verify a module/attribute evaluates.
  - Example: `nix eval .#nixosConfigurations.thinkbook.config --json`
  - Notes: use `--show-trace` for evaluation traces.

- Show flake outputs (introspect exports):
  - `nix flake show .`
  - Example: `nix flake show . --json`

## Build / Produce artifacts
- Build a flake output (derivation/artifact):
  - `nix build .#<attribute>`
  - Goal: produce activation packages or toplevels.
  - Example: `nix build .#homeConfigurations.sid.activationPackage`
  - Notes: add `--no-link` to avoid creating `result` symlink.

- Build NixOS system toplevel:
  - `nix build .#nixosConfigurations.<host>.config.system.build.toplevel`
  - Example: `nix build .#nixosConfigurations.thinkbook.config.system.build.toplevel`

## Run / Dev shells
- Run a package from the flake:
  - `nix run .#<package>`
  - Example: `nix run nixpkgs#jq`

- Enter a development shell:
  - `nix develop .#devShell` or `nix develop`
  - Goal: spawn reproducible developer environment.

## Flake maintenance
- Update flake inputs (refresh `flake.lock`):
  - `nix flake update`

- Run flake checks (if provided):
  - `nix flake check`

## Home Manager (flakes)
- Build HM activation package:
  - `nix build .#homeConfigurations.<user>.activationPackage`
  - Example: `nix build .#homeConfigurations.sid.activationPackage`

- Apply Home Manager config (flake):
  - `home-manager switch --flake .#<user>`

## NixOS system actions
- Rebuild & switch the system (mutating, requires root):
  - `sudo nixos-rebuild switch --flake .#<host>`

- Build only (non-switch):
  - `sudo nixos-rebuild build --flake .#<host>`

## Profile / package management
- Install a package in your user profile:
  - `nix profile install nixpkgs#<package>`
  - Example: `nix profile install nixpkgs#ripgrep`

- List user profile packages:
  - `nix profile list`

## Search / Inspect
- Search nixpkgs for a package:
  - `nix search nixpkgs <term>`

## Cleanup & store maintenance
- Collect garbage:
  - `sudo nix-collect-garbage -d`

## Store & logs (debugging builds)
- Show build logs:
  - `nix log /nix/store/<path>-drv` or `nix log /nix/store/<path>`

- Inspect path info:
  - `nix path-info --json /nix/store/<...>`

## Helpful flags & tips
- Use `--show-trace` for evaluation errors.
  - Example: `nix eval .#lib --show-trace`
- Use `--no-link` with `nix build` to avoid `result` symlink.
- Use `--json` / `--raw` for machine-friendly output in scripts.
- Run commands from the repo root (where `flake.nix` is) so `.#` attributes resolve.
- Prefer non‑mutating `nix eval` and `nix build` checks before `nixos-rebuild switch` or `home-manager switch`.

## Common workflows (recipes)
- Quick option evaluation:
  - `nix eval .#lib`
  - `nix eval .#nixosConfigurations.<host>.config`

- Build HM activation to validate user config:
  - `nix build .#homeConfigurations.<user>.activationPackage`

- Test system build before deploy:
  - `nix build .#nixosConfigurations.<host>.config.system.build.toplevel`

- Apply system changes (when ready):
  - `sudo nixos-rebuild switch --flake .#<host>`

## Safety & environment
- Confirm you are in the repo root when using `.#` attributes.
- Use `--show-trace` for helpful error traces.
- Test system changes in a VM first.

---

Want this added to `assets/ricing/README.md` or saved as-is at `assets/ricing/NIX-CHEATSHEET.md`? (Already saved to `assets/ricing/NIX-CHEATSHEET.md`.)
