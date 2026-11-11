{
  config,
  pkgs,
  ...
}:

{
  home.packages = with pkgs; [
    adwaita-icon-theme
    awscli2
    bc
    latest.chromium
    clang
    cmake
    dconf2nix
    unstable.deno
    deskflow
    dig
    discord
    dunst
    fastfetch
    fd
    file-roller
    latest.firefox
    #(flameshot.override { enableWlrSupport = true; })
    #gcc
    mesa-demos
    gimp
    go
    graphviz
    kubernetes-helm
    htop
    jdk21_headless
    jetbrains.idea
    jq
    kubectl
    libreoffice
    lld
    lm_sensors
    lsof
    gnumake
    nil
    package-version-server
    nixos-anywhere
    nodejs
    obsidian
    obs-studio
    openssl
    pastel
    pciutils
    pinentry-gnome3
    playerctl
    podman-compose
    postgresql_17
    protobuf
    python3
    remmina
    ripgrep
    sbomnix
    seahorse
    spice-vdagent
    sqlite
    latest.thunderbird
    tree-sitter
    unzip
    vhs
    virtui
    visualvm
    wget
    yarn-berry
    zip
  ];

  home.homeDirectory = "/home/${config.home.username}";

  home.sessionVariables = {
    EDITOR = "hx";
  };
  # Disabled due to `home-manager.useGlobalPkgs = true;`.
  # imports = [
  #   ../shared/unfree.nix
  # ];
  # The `nixpkgs.overlays` option is already defined in nixos modules.
  # nixpkgs.overlays = outputs.overlays;
}
