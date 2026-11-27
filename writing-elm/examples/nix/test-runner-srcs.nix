# elm-test-rs builds its test runner from this Elm package, which elm.json
# does not list, so elm2nix cannot pin it. elm-test-rs 3.2.0 requires 6.0.1;
# its other dependencies are already in elm-srcs.nix. When nixpkgs updates
# elm-test-rs and it reports "there is no version of
# mpizenberg/elm-test-runner in X", pin version X here with the sha256 from
# `nix-prefetch-url https://github.com/mpizenberg/elm-test-runner/archive/X.tar.gz`.
{
  "mpizenberg/elm-test-runner" = {
    sha256 = "0r9y2mmsqky7w3gq4hx25yxm0qw4j950iaqnc4kzpiaw0rg1xaf5";
    version = "6.0.1";
  };
}
