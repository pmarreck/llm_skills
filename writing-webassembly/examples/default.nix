# WebAssembly examples, built and run offline with nixpkgs tools. Each
# derivation is a check that fails if its example misbehaves.
{ pkgs }:
let
  # nixpkgs' ordinary rustc has no wasm32-wasip1 standard library. The WASI
  # cross package set's build-platform rustc runs on the host, targets
  # wasm32-wasip1, includes std, and comes from the binary cache. Linking
  # needs lld's wasm-ld named explicitly.
  rustc = pkgs.pkgsCross.wasi32.buildPackages.rustc;
  compileWasi =
    source: output:
    "${rustc}/bin/rustc --edition 2024 -O --target wasm32-wasip1"
    + " -C linker=${pkgs.lld}/bin/wasm-ld -C linker-flavor=wasm-ld"
    + " ${source} -o ${output}";
in
{
  # WAT operand order, traps and WAST assertions against the production module.
  wat = pkgs.runCommand "webassembly-example-wat" { nativeBuildInputs = [ pkgs.wasmtime pkgs.wasm-tools ]; } ''
    export HOME="$TMPDIR" # wasmtime writes its compilation cache under HOME
    wasm-tools validate ${./wat/math.wat}
    wasm-tools parse ${./wat/math.wat} -o math.wasm
    cat ${./wat/math.wat} ${./wat/math-tests.wast} > math.wast
    wasmtime wast math.wast
    # Invoking an export with arguments works but warns that it is experimental.
    result="$(wasmtime run --invoke neg math.wasm 5 2> invoke.err)"
    if [ "$result" != "-5" ]; then
      cat invoke.err >&2
      echo "neg(5) returned '$result', expected -5" >&2
      exit 1
    fi
    touch "$out"
  '';

  # A WASI program confined to a preopened directory whose guest path it
  # receives through the environment, with paths outside it denied.
  wasi-sandbox = pkgs.runCommand "webassembly-example-wasi-sandbox" { nativeBuildInputs = [ pkgs.wasmtime ]; } ''
    export HOME="$TMPDIR"
    ${compileWasi ./wasi/sandbox.rs "sandbox.wasm"}
    host="$(mktemp -d)"
    wasmtime run --dir "$host::/tmp" --env APP_TEST_TMPDIR=/tmp sandbox.wasm > out.txt
    cat out.txt
    grep -q '^INSIDE_OK hello sandbox$' out.txt
    grep -q '^OUTSIDE_DENIED /etc/passwd' out.txt
    grep -q '^OUTSIDE_DENIED /not-preopened/x.txt' out.txt
    if [ -n "$(ls -A "$host")" ]; then
      echo "the guest left files in the preopened directory" >&2
      exit 1
    fi

    # Without the preopen, the same guest path does not exist.
    if wasmtime run --env APP_TEST_TMPDIR=/tmp sandbox.wasm > nodir.out 2> nodir.err; then
      echo "the guest wrote to /tmp without a preopened directory" >&2
      exit 1
    fi
    grep -q 'create /tmp/scratch.txt' nodir.err
    touch "$out"
  '';

  # std::env::temp_dir() panics on WASI even with TMPDIR set; an injected,
  # preopened path works.
  wasi-temp-dir = pkgs.runCommand "webassembly-example-wasi-temp-dir" { nativeBuildInputs = [ pkgs.wasmtime ]; } ''
    export HOME="$TMPDIR"
    ${compileWasi ./wasi/temp_dir_trap.rs "trap.wasm"}

    status=0
    wasmtime run --env TMPDIR=/tmp trap.wasm > trap.out 2> trap.err || status=$?
    cat trap.out trap.err
    if [ "$status" -eq 0 ]; then
      echo "temp_dir() returned instead of panicking" >&2
      exit 1
    fi
    grep -q '^calling temp_dir$' trap.out
    grep -q 'not supported by WASI yet' trap.err
    if grep -q UNREACHABLE trap.out; then
      echo "temp_dir() returned a path" >&2
      exit 1
    fi

    host="$(mktemp -d)"
    wasmtime run --dir "$host::/tmp" --env APP_TEST_TMPDIR=/tmp trap.wasm > ok.out
    cat ok.out
    grep -q '^INJECTED_DIR_OK /tmp$' ok.out
    touch "$out"
  '';
}
