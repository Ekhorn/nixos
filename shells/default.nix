{
  pkgs ? import <nixpkgs> { },
}:

pkgs.mkShell {
  packages = with pkgs; [
    curl
    fd
    helix
    htop
    jq
    ripgrep
  ];
}
