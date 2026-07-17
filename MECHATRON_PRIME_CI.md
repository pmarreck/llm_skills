# Mechatron Prime CI

Thelio builds signed GitHub `push` events on `yolo`, `master`, or `main` for
every `pmarreck/*` repository. Builds are sequential; no GitHub Actions or
Garnix configuration is needed.

The previously audited fleet keeps its root-owned target fallback during this
migration. A committed manifest always wins; every new project needs one.

## Per project

1. Commit `.mechatron-prime/targets` with one existing Nix flake attribute per
   line. For example:

   ```text
   packages.x86_64-linux.default
   checks.x86_64-linux.test
   ```

   Use `nix flake show` to choose real attributes. Blank lines and `#` comments
   are allowed. The exact pushed commit supplies this file, so changing targets
   needs only a normal repository commit, not a Thelio rebuild.

2. Provision its GitHub webhook from Thelio after the Mechatron deployment:

   ```bash
   sudo bash -c 'set -u; source /etc/mechatron-prime/github-webhook.env; printf "%s\n" "$MECHATRON_GITHUB_WEBHOOK_SECRET"' \
     | sudo -u pmarreck -H env XDG_CONFIG_HOME=/home/pmarreck/.config \
         /home/pmarreck/Code/mechatron-prime/scripts/provision-mechatron-webhooks \
         --owner pmarreck --all-owner-repos \
         --endpoint https://thelio-nixos.tail66c90.ts.net/hooks/github
   ```

   Add `--dry-run` first to review the whole fleet without GitHub writes.
   The explicit `XDG_CONFIG_HOME` preserves Peter's authenticated `gh` session
   when the provisioner runs under `sudo`; the script never takes the secret as
   an argument.

3. Push `yolo`, `master`, or `main`. Its first accepted build creates the badge
   JSON.

## README badge

Replace only `REPOSITORY` with the case-preserving GitHub repository basename.

```markdown
[![Mechatron Prime CI](https://img.shields.io/endpoint?url=https%3A%2F%2Fthelio-nixos.tail66c90.ts.net%2Fbadges%2FREPOSITORY.json&style=for-the-badge)](https://thelio-nixos.tail66c90.ts.net/mechatron-prime/)
```

The image is dynamic (`BUILDING`, `PASSING`, or `FAILING`); its click target is
the shared public Mechatron Prime explanation page.
