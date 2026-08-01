# secrets/ — sops-nix encrypted secrets

Managed by [sops-nix](https://github.com/Mic92/sops-nix). Decrypted at runtime
to `/run/secrets/` using the host SSH key — nothing secret is stored in the
Nix store or in plaintext in this repo.

## Layout

- `secrets.yaml` — the encrypted store. Currently a **plaintext placeholder**
  so Nix can evaluate; it will fail at `switch` until replaced (by design).
- `.sops.yaml` — age key authorisation (author this before encrypting).

## One-time bootstrap (on the target machine, before the first switch)

```sh
# 1. Install helpers
nix profile install nixpkgs#age nixpkgs#ssh-to-age

# 2. Derive an age public key from the host's SSH host key
ssh-to-age < /etc/ssh/ssh_host_ed25519_key.pub

# 3. Author secrets/.sops.yaml with the printed age key
$EDITOR .sops.yaml

# 4. Create a yescrypt password hash
mkpasswd -m yescrypt

# 5. Create + encrypt the store
sops secrets/secrets.yaml
#   → add key `users/sid/password` = the hash from step 4

# 6. Switch (this now decrypts /run/secrets/users/sid/password)
nixos-rebuild switch --flake ~/nixos#thinkbook
```

> The module reads `sops.age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ]`
> (modules/system/core/secrets.nix) and exposes the secret at
> `/run/secrets/users/sid/password` for the `sid` user account.

## Adding a new secret

1. `sops secrets/secrets.yaml` — add the key.
2. Reference it in a module:
   ```nix
   sops.secrets."my/app/key" = { neededForUsers = true; }; # optional
   ```
3. Use `config.sops.secrets."my/app/key".path` in the module that needs it.
