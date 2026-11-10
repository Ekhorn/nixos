{
  pkgs ? import <nixpkgs> { },
}:

let
  commit = "7cc8a6b08a51d3fd23b9c4fd2493e7e888e88507"; # 1.59.1
  sha256 = "sha256:0i62ss2y3bv5jc9dwydvrnc3dl5x0hpg2q4i5plj6h7d5x9wlard";
  playwrightShell = import ./playwright.nix { inherit pkgs commit sha256; };
in
pkgs.mkShellNoCC {
  buildInputs = with pkgs; [
    protobuf
    grpc
  ];
  inputsFrom = [ playwrightShell ];
  packages = with pkgs; [
    openjdk21_headless
    nodejs_24
    corepack_24
  ];
  shellHook = ''
    ${playwrightShell.shellHook or ""}
  '';
}
