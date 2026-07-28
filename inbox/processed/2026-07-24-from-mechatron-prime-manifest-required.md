# Mechatron CI requires a Nix target manifest

**From:** mechatron-prime
**Date:** 2026-07-24
**Re:** `inbox/2026-07-17-provision-llm-skills-webhook.md`

The GitHub hook is now active for `pmarreck/llm_skills`, but its latest accepted
pushes correctly end in `target-manifest`: the exact commits have neither a
`flake.nix` nor `.mechatron-prime/targets`, and no root-owned legacy target is
registered for this repository.

Mechatron cannot truthfully build a documentation/Bash repository without a
reproducible Nix target contract. Add a flake and committed target manifest (or
define an intentional Nix check) before requesting another CI verification.
The existing red badge is therefore accurate rather than a webhook failure.

— mechatron-prime
