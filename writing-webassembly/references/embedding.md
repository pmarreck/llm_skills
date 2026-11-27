# Embedding Wasm in a host

Running guest Wasm inside a native or browser host, often to sandbox
untrusted or hot-reloaded code. The fleet lessons here come from Aedicule (a
Wasmtime-hosted frontplane) and its WAT applications.

## Bound every guest call

A guest can loop forever. Give each call a budget:

- **Fuel** counts executed work deterministically: the same inputs consume
  the same fuel, so a budget failure reproduces. Enable it in the engine
  configuration and set the fuel before each call.
- **Epoch interruption** is cheaper and wall-clock based. Use it when a
  deadline matters more than reproducibility.

Size budgets per call, not per request. A request that is reasonable overall
can still exceed one call's fuel: a headless run of 300 game ticks failed
once gameplay grew, although each tick was well bounded. The host now splits
long requests into calls of at most 60 ticks and refuels between them, so
every slice enforces the same deterministic ceiling.

Also bound memory (a maximum on linear memory growth, or a store limiter)
and stack depth, and treat a trap as an ordinary error the host reports,
never as a host crash.

## Hot reload is a transaction

Reloading a guest module while the host runs needs:

- an explicit, versioned state schema that the new module validates before
  taking over;
- a candidate swap: instantiate and validate the new module first, and keep
  the old one running if anything fails;
- resetting edge-triggered input (a key press already consumed) while
  keeping persistent toggles.

## Keep guest code out of the host's build closure

If the host is built with Nix, keep application `.wat` or `.wasm` files out
of the host derivation's source, even through an unused `include_str!`.
Otherwise every guest edit rebuilds and relinks the host. Package guests as
their own derivation, load them at runtime, and add a structural test that
rejects guest files in the host's source closure. A small fallback module
that is part of the host's stable ABI may be embedded.

## Files and I/O in sandboxed runtimes

A WASI guest sees only the directories the host preopens (see
[WASI](wasi.md)). wazero's default sandbox, for example, cannot open an
arbitrary host path. For tools and benchmarks, pass input on stdin and read
output from stdout rather than granting directory access, unless file access
is what is being tested.

## Browser hosts

When the module's memory grows, existing JavaScript views of it
(`Uint8Array` over `memory.buffer`) are detached and must be recreated
(*researched*). Re-read `memory.buffer` after any call that might allocate.
