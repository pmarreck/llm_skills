# Ecosystem lore and community context

Read this before choosing an implementation, contributing to an upstream
venue, or discussing governance. Check the linked live policies again before
submitting because this section is time-sensitive.

## Lineage and current projects

| Project | Relationship | Position stated by that project |
|---|---|---|
| Nix / Nixpkgs / NixOS | Upstream package manager, package set, and operating system | Official Nix projects use an elected Steering Committee for technical/community leadership and a foundation board for legal, financial, and partnership matters. |
| GNU Guix | Separate GNU package manager and distribution, announced in 2012 | Guix began on Nix's low-level build/store mechanisms while replacing the Nix language with Guile Scheme. It has since developed as its own GNU system with a stronger software-freedom policy. |
| Lix | Community fork of the C++ Nix implementation; last shared release 2.18 | Lix promises compatibility with existing Nix/NixOS configurations and flakes while pursuing independent community governance, clearer stability boundaries, and implementation changes. It is outside the NixOS Foundation. |
| Determinate Nix | Commercial downstream Nix distribution, not described by its vendor as a fork | Determinate Systems promises Nix-ecosystem compatibility, stable flakes, and enterprise features. Its installer policy and feature set can differ from upstream Nix. |
| Snix | Ground-up Rust implementation of Nix concepts | Snix pursues modular replacement components and does not yet imply drop-in parity with C++ Nix. |

## Practical comparison

### Upstream Nix

- **Advantages relative to upstream Nix:** This is the baseline: official NixOS
  integration, the reference evaluator/daemon behavior, and the compatibility
  target used by Nixpkgs.
- **Tradeoffs relative to upstream Nix:** Flakes remain experimental upstream;
  downstreams and forks make first-party claims of faster evaluation, clearer
  diagnostics, or stronger stability contracts that upstream does not promise.
- **Side-by-side:** Multiple `nix` client binaries can be invoked deliberately,
  but a normal host has one active `/nix/store` and daemon protocol endpoint.
  Do not install competing daemon distributions over one another without a
  documented migration or NixOS module transition.

### Lix

- **Advantages relative to upstream Nix:** Lix reports improved diagnostics,
  an 8–20% performance gain over Nix 2.18, a Meson-based development build,
  explicit stability boundaries, and community governance independent of a
  company or the NixOS Foundation.
- **Tradeoffs relative to upstream Nix:** It is a diverging fork. It does not
  include upstream lazy trees, plans different content-addressed derivation
  work, and may intentionally tighten or evolve behavior. Compatibility should
  be tested for evaluator extensions and operational tooling.
- **Side-by-side:** The supported installer path calls conversion an “upgrade”
  of an existing Nix installation. Lix becomes the `nix` client/daemon over the
  existing `/nix/store`; it is not a second independent package-manager service.
  NixOS and nix-darwin can select Lix declaratively while remaining NixOS or
  nix-darwin systems.

### Determinate Nix

- **Advantages relative to upstream Nix:** Its current documentation lists
  parallel evaluation, lazy trees, a native Linux builder on macOS, WebAssembly
  in expressions, managed configuration, a defined security process, and a
  vendor-backed flake stability guarantee.
- **Tradeoffs relative to upstream Nix:** The vendor controls release and
  installer policy, generates configuration values that it tells users not to
  edit directly, and integrates with commercial services. Some upstream manual
  instructions do not apply, and vendor extensions can create portability
  assumptions absent from upstream Nix.
- **Side-by-side:** Migration upgrades the installation in place and keeps the
  existing Nix store and profiles. On NixOS, its module replaces the selected
  Nix implementation. Treat upstream and Determinate daemons as alternatives,
  not simultaneously independent stores.

### GNU Guix

- **Advantages relative to upstream Nix:** Guix offers Guile Scheme APIs for
  package definitions and builders, a GNU operating-system distribution, and a
  package policy centered on software freedom. Its language and package model
  are programmable through a general-purpose Lisp.
- **Tradeoffs relative to upstream Nix:** Guix package definitions and system
  services form a separate ecosystem. It does not consume Nixpkgs expressions
  as an alternate frontend, and its software-freedom rules exclude packages
  that Nixpkgs can expose as unfree.
- **Side-by-side:** Supported on an existing GNU/Linux “foreign distro,”
  including a NixOS host in principle. Guix uses `/gnu/store` and `/var/guix`
  and says it complements the host package manager without interference. Guix
  packages may coexist in userspace; Guix System would be a separate booted OS
  or installation target.

### Snix

- **Advantages relative to upstream Nix:** Rust components expose Nix data
  formats and evaluator/store functions as libraries. Its modular store can be
  served through gRPC, FUSE, virtiofs, or a Nix binary-cache bridge, allowing
  experiments that are difficult inside the monolithic C++ implementation.
- **Tradeoffs relative to upstream Nix:** Snix states that its APIs are unstable
  and that no full-featured drop-in replacement exists yet. It is suitable for
  component adoption and experiments, not an unqualified NixOS control plane.
- **Side-by-side:** Yes for its current component tools. A Nix installation can
  communicate with `snix-store` through `nar-bridge` or use Snix libraries and
  CLI tools separately. This is composition, not two complete OS managers.

Treat compatibility as a tested claim, not a synonym. Lock handling, evaluator
features, CLI flags, daemon behavior, and experimental-feature policy can
differ even when ordinary Nixpkgs evaluation succeeds.

## What happened in 2024

The following summary distinguishes records from interpretation.

**Documented events:** Disputes around military-industry sponsorship, conflicts
of interest, moderation, representation, leadership, and unclear decision
authority culminated in a public governance crisis. The Foundation board's
May 1, 2024 statement acknowledged that series of issues, announced Eelco
Dolstra's departure from the board, and started a transfer toward
community-based governance. A Constitutional Assembly produced a constitution,
and the first elected Steering Committee took office later in 2024.

**Positions, not neutral facts:** Participants disagreed on whether accepting a
sponsor constitutes endorsement, which organizations should be eligible, how
moderation should work, and how founder or corporate influence should be
limited. Lix describes its independence and community policy as a response to
commercial and governance concerns. Determinate Systems rejects the claim that
it controls upstream Nix and presents its distribution as a compatible,
professionally maintained downstream.

**Contributor inference:** Technical work need not relitigate this history.
Changes involving governance, sponsorship, moderation, installer defaults,
official branding, or implementation choice can touch unresolved values and
institutional trust. In those cases, cite the current policy, disclose relevant
affiliations, avoid assigning motives, and identify whose position a claim
represents.

Current official governance delegates broad technical/community authority to
an elected Steering Committee and Nixpkgs-specific authority to a Nixpkgs core
team. Most implementation and review remains distributed among volunteers.

## Nixpkgs contribution posture

Read the repository's current `CONTRIBUTING.md` before preparing a submission.
As of August 2026, it requires:

- a responsible human who understands and reviews every contribution;
- transparent disclosure of non-trivial automation, including LLM use;
- an `Assisted-by:` Git trailer naming the tool and primary model when LLM
  output materially enters a commit;
- separate disclosure for PR descriptions, reviews, comments, and other
  generated communication;
- sandboxed build testing and execution of shipped binaries;
- narrow, reviewable changes and patient follow-up with volunteer reviewers.

This is venue-specific and supersedes a contributor's ordinary local commit
conventions for commits offered to Nixpkgs. Research, tests, debugging, and
private review may be out of disclosure scope when no substantial generated
output enters the contribution, but the human remains accountable and should
disclose significant technical influence where relevant.

For package work, use `nixpkgs-review` and the PR template. Keep unrelated
refactors out of a version update. Explain intention and evidence so a reviewer
can assess the package without reconstructing the work.

## Decision guide

- Choose upstream Nix when matching NixOS defaults and official Nix behavior is
  the priority.
- Consider Lix when its community policy, diagnostics, or technical direction
  matters, then test the project's actual flake and daemon behavior.
- Choose Determinate Nix deliberately when accepting its vendor relationship,
  installer defaults, and added contracts.
- Study Snix for modular Rust components; do not promise parity without a
  task-specific compatibility test.
- Choose Guix when its Scheme APIs, GNU integration, or software-freedom policy
  fits the project. It is a separate package ecosystem, not an alternate
  Nixpkgs frontend.

## Primary and first-party records

- [Current Nix governance](https://nixos.org/governance/)
- [Nixpkgs core team](https://nixos.org/community/teams/nixpkgs-core/)
- [Nixpkgs contribution policy](https://github.com/NixOS/nixpkgs/blob/master/CONTRIBUTING.md)
- [May 2024 board statement and governance transfer](https://discourse.nixos.org/t/nixos-foundation-board-giving-power-to-the-community/44552)
- [2024 Steering Committee election](https://nixos.org/blog/announcements/2024/sc-election-2024/)
- [Lix project description](https://lix.systems/about/)
- [Lix compatibility and governance FAQ](https://lix.systems/faq/)
- [Lix installation and conversion](https://lix.systems/install/)
- [Determinate Nix announcement](https://determinate.systems/blog/announcing-determinate-nix/)
- [Determinate Nix features](https://docs.determinate.systems/determinate-nix/)
- [Migrating from upstream Nix](https://docs.determinate.systems/guides/migrating-from-upstream-nix/)
- [Original 2012 Guix announcement](https://lists.gnu.org/archive/html/guile-user/2012-07/msg00006.html)
- [GNU Guix manual](https://guix.gnu.org/manual/devel/en/guix.pdf)
- [Snix project status and components](https://snix.dev/about/)
