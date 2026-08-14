# Secrets (sops-nix) — repository playbook

This repository uses `sops` + `sops-nix` for secrets. The default backend is
`age-ssh` (SSH-agent backed age encryption). This file documents the common
workflows.

Basic workflow

1. Add a recipient (public SSH key):

   - Add the admin's SSH public key to `secrets/recipients.json` (push a PR).

2. Encrypt a secret (`sops` with age-ssh):

   - Locally, ensure your SSH agent has the private key loaded (e.g. `ssh-add`).
   - Create plaintext `secrets/users/sid/password` and run:

       sops --encrypt --age <AGE-RECIPIENT> secrets/users/sid/password > secrets/users/sid/password.sops

   - Commit the `.sops` file only. Do not commit plaintext.

3. Test rebuild locally:

   - Make sure your SSH agent is available and run:

       nixos-rebuild switch --flake .#thinkbook

   - This will evaluate `sops-nix` and should populate the Nix store with
     the decrypted secret path referenced by modules (see `modules/users/sid.nix`).

CI considerations

- CI systems can decrypt secrets by provisioning an ephemeral age key in the CI
  secret store and making it available to the build. Prefer short-lived keys.
- Alternatively, use a central secret manager (Vault/KMS) for CI; see decision
  notes in the top-level documentation if you choose this route.

Key rotation & recovery

- To rotate a key: add the new public key to `secrets/recipients.json`, re-encrypt
  secrets so both keys can decrypt, verify access, then remove the old key and
  re-encrypt again.
- Keep a recovery private key offline in a secure location (hardware token or
  an encrypted drive in a safe). Test recovery regularly.

Security notes

- Decryption occurs at build/evaluation time and secrets end up in the Nix
  store. Treat build artifacts and Nix store paths as sensitive.
- Prefer hardware-backed SSH keys (YubiKey) and SSH agents to avoid storing
  private key files on disk.

