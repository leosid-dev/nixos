# Secrets (sops-nix) — repository playbook

This repository uses `sops` + `sops-nix` for secrets. The only supported
backend is age decryption through the host SSH key. The configured secret
store is `secrets/secrets.yaml`.

Basic workflow

1. Derive the host recipient from the target machine's SSH host key:

       ssh-to-age < /etc/ssh/ssh_host_ed25519_key.pub

2. Put that recipient in the active `creation_rules` entry in
   `secrets/.sops.yaml`.

3. Edit the configured store with:

       sops secrets/secrets.yaml

   Set `users/sid/password` to the output of `mkpasswd -m yescrypt`.

4. Commit the encrypted `secrets/secrets.yaml` only. Never commit plaintext.

5. Test rebuild locally:

   - Make sure your SSH agent is available and run:

       nixos-rebuild switch --flake .#thinkbook

   - This will evaluate `sops-nix` and populate the runtime secret path
     referenced by `modules/users/sid.nix`.

CI considerations

- CI systems can decrypt secrets by provisioning an ephemeral age key in the CI
  secret store and making it available to the build. Prefer short-lived keys.
- Alternatively, use a central secret manager (Vault/KMS) for CI; see decision
  notes in the top-level documentation if you choose this route.

Key rotation & recovery

- To rotate a key: add the new age recipient to `secrets/.sops.yaml`, re-encrypt
  the store so both keys can decrypt, verify access, then remove the old
  recipient and re-encrypt again.
- Keep a recovery private key offline in a secure location (hardware token or
  an encrypted drive in a safe). Test recovery regularly.

Security notes

- sops-nix decrypts secrets during activation into runtime paths. Treat the
  encrypted repository and any activation/build logs as sensitive.
- Prefer hardware-backed SSH keys (YubiKey) and SSH agents to avoid storing
  private key files on disk.
