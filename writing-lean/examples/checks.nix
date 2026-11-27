# Compiles every example with nixpkgs' Lean, offline. The check fails when a
# file does not compile, prints any warning (including "declaration uses
# `sorry`"), has no `#print axioms` report, or proves something that depends
# on an axiom other than Lean's standard three. A `native_decide` proof fails
# here, because its generated `._native.` axiom is not on that list.
{ pkgs }:
let
  inherit (pkgs) lib;
  examples = lib.fileset.toSource {
    root = ./.;
    fileset = lib.fileset.fileFilter (file: file.hasExt "lean") ./.;
  };
in
pkgs.runCommand "writing-lean-examples"
  {
    nativeBuildInputs = [ pkgs.lean4 ];
  }
  ''
    status=0
    count=0
    for file in ${examples}/*.lean; do
      name="''${file##*/}"
      count=$((count + 1))
      failed=0
      if ! output="$(lean "$file" 2>&1)"; then
        printf '%s does not compile:\n%s\n' "$name" "$output" >&2
        status=1
        continue
      fi
      if printf '%s\n' "$output" | grep -E -q '(warning|error):'; then
        printf '%s prints warnings:\n%s\n' "$name" "$output" >&2
        failed=1
      fi
      # Theorem names may end in a prime, such as sub_add_cancel followed by
      # an apostrophe, so the quoted name is matched greedily.
      directives="$(grep -c '^#print axioms ' "$file" || true)"
      reports="$(printf '%s\n' "$output" | grep -c -E "^'.+' (depends on axioms: \[|does not depend on any axioms)" || true)"
      if [ "$directives" -lt 1 ] || [ "$reports" -ne "$directives" ]; then
        printf '%s: %s #print axioms directives, %s reports\n' "$name" "$directives" "$reports" >&2
        failed=1
      fi
      extra="$(printf '%s\n' "$output" \
        | sed -n "s/^'.*' depends on axioms: \[\(.*\)\]$/\1/p" \
        | tr ',' '\n' | tr -d ' ' \
        | grep -v -x -E 'propext|Classical\.choice|Quot\.sound' || true)"
      if [ -n "$extra" ]; then
        printf '%s depends on nonstandard axioms:\n%s\n' "$name" "$extra" >&2
        failed=1
      fi
      if [ "$failed" -eq 0 ]; then
        printf '%s: ok (%s axiom reports)\n' "$name" "$reports"
      else
        status=1
      fi
    done
    if [ "$count" -eq 0 ]; then
      echo "no examples found" >&2
      status=1
    fi
    [ "$status" -eq 0 ] && touch "$out"
    exit "$status"
  ''
