{
  pkgs ? import <nixpkgs> { },
}:

pkgs.mkShellNoCC {
  packages = with pkgs; [
    curl
    fd
    helix
    htop
    jq
    ripgrep
  ];
}
