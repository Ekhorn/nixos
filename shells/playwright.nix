{
  pkgs ? import <nixpkgs> { },
  commit ? "e462a75ad44682b4e8df740e33fca4f048e8aa11", # fallback to v1.52.0
  sha256 ? "sha256:1q4h9z3fkrz4bzi66d6p9b865rj5hd7y4krnpg48f7pagyxvvn02", # fallback to v1.52.0
}:

let
  src = fetchTarball {
    url = "https://github.com/NixOS/nixpkgs/archive/${commit}.tar.gz";
    inherit sha256;
    # sha256 = ""; # Use to get SHA256
  };
  playwright-driver = (import src { system = pkgs.stdenv.hostPlatform.system; }).playwright-driver;
in
pkgs.mkShellNoCC {
  nativeBuildInputs = [ playwright-driver ];
  shellHook = ''
    export PLAYWRIGHT_BROWSERS_PATH=${playwright-driver.browsers}
    export PLAYWRIGHT_SKIP_VALIDATE_HOST_REQUIREMENTS=true
    # Required for Webkit
    export PLAYWRIGHT_HOST_PLATFORM_OVERRIDE="ubuntu-24.04"
  '';
}
