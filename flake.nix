{
	description = "Shared agent skills, their Bash tooling, and the suite that proves it";

	inputs = {
		nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
		# capture.bash is Peter's canonical stdout/stderr/exit-code primitive. It
		# is consumed as a flake input rather than vendored so the suite keeps
		# testing the real thing instead of a copy that can silently drift.
		dotfiles = {
			url = "github:pmarreck/dotfiles";
			flake = false;
		};
	};

	outputs = { self, nixpkgs, dotfiles }:
		let
			systems = [
				"x86_64-linux"
				"aarch64-linux"
				"aarch64-darwin"
			];
			forAllSystems = nixpkgs.lib.genAttrs systems;
			pkgsFor = system: nixpkgs.legacyPackages.${system};
			# Every external executable the suite is allowed to use. The build
			# sandbox supplies exactly these and nothing else, so a dependency
			# that is only satisfied by a globally installed tool fails here
			# rather than surviving as a false green.
			suiteTools = pkgs: with pkgs; [
				bash
				coreutils
				diffutils
				findutils
				gawk
				gitMinimal
				gnugrep
				gnused
				ripgrep
			];
		in {
			checks = forAllSystems (system:
				let pkgs = pkgsFor system;
				in {
					test = pkgs.runCommand "llm-skills-test"
						{
							src = self;
							nativeBuildInputs = suiteTools pkgs;
							# Resolved by the tests instead of $HOME/dotfiles, which
							# does not exist in the sandbox.
							CAPTURE_LIB = "${dotfiles}/bin/src/capture.bash";
						}
						''
							cp -r "$src" ./repo
							chmod -R u+w ./repo
							cd ./repo

							# The Linux build sandbox has no /usr/bin/env, so every
							# `#!/usr/bin/env bash` script is unrunnable until its
							# shebang is rewritten to a store path.
							patchShebangs ./test ./install ./tests ./.githooks \
								./memories/scripts

							# The suite writes sandboxes under TMPDIR and needs a
							# writable HOME; the sandbox provides neither by default.
							export HOME="$TMPDIR/home"
							mkdir -p "$HOME"

							# Several tests init throwaway Git repos; Git refuses to
							# commit without an identity.
							export GIT_CONFIG_GLOBAL="$TMPDIR/gitconfig"
							git config --global user.email "test@example.invalid"
							git config --global user.name "llm-skills test"
							git config --global init.defaultBranch yolo

							# Zone names are unresolvable without the tz database, so
							# TZ=Asia/Kolkata would silently fall back to UTC and make
							# the migrator's local-time assertion pass for the wrong
							# reason.
							export TZDIR="${pkgs.tzdata}/share/zoneinfo"

							# `nix build` copies tracked files but not .git, so
							# assertions that ask Git about this repo (check-ignore,
							# core.hooksPath) have nothing to query. Reconstitute a
							# real repository from the copied tree; .gitignore is
							# tracked, so Git's own ignore engine still evaluates the
							# committed rules rather than a grep approximation.
							git init -q .
							git add -A
							git commit -qm "sandbox checkout"

							# about-peter/SKILL.md is deliberately a dangling symlink
							# into the sibling PRIVATE llm-skills-private repo, which
							# by design is absent here. Stand up a placeholder sibling
							# so CI mirrors a provisioned machine. The warn-and-skip
							# path for a genuinely unmaterializable skill keeps its own
							# dedicated coverage in test_codex_sync's fixtures, so
							# nothing is lost by satisfying this one.
							mkdir -p ../llm-skills-private/about-peter
							printf '%s\n' \
								'---' \
								'name: about-peter' \
								'description: Placeholder standing in for the private context pack during CI.' \
								'---' \
								> ../llm-skills-private/about-peter/SKILL.md

							./test
							touch "$out"
						'';
				});

			devShells = forAllSystems (system:
				let pkgs = pkgsFor system;
				in {
					default = pkgs.mkShell {
						packages = suiteTools pkgs ++ [ pkgs.shellcheck ];
					};
				});
		};
}
