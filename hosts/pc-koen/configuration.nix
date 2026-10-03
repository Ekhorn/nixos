{
  config,
  inputs,
  outputs,
  pkgs,
  ...
}:

{
  imports = [
    ./hardware-configuration.nix
    inputs.home-manager.nixosModules.home-manager
    inputs.nix-flatpak.nixosModules.nix-flatpak
    ./flatpak.nix
    ../../modules/nixos/nvidia.nix
  ]
  ++ (builtins.attrValues outputs.nixosModules);

  boot.binfmt.emulatedSystems = [ "aarch64-linux" ];

  hardware.bluetooth.powerOnBoot = true;

  home-manager = {
    backupFileExtension = "backup";
    useGlobalPkgs = true;
    useUserPackages = true;
    users.${config.user.username} = import ./home.nix;
  };

  networking.hostName = "pc-koen";
  networking.networkmanager.enable = true;
  networking.firewall.interfaces.enp6s0.allowedTCPPorts = [ 42420 ];

  programs.steam.enable = true;

  users.groups.github-runner = { };
  users.users.github-runner = {
    isNormalUser = true;
    group = "github-runner";
    extraGroups = [ "docker" ];
  };

  services.flatpak.enable = true;
  services.gnome.gnome-remote-desktop.enable = true;
  services.github-runners.spaced.enable = false;
  services.github-runners.spaced.user = "github-runner";
  services.github-runners.spaced.url = "https://github.com/Ekhorn/spaced";
  services.github-runners.spaced.tokenFile = "/etc/gh_token";
  services.github-runners.spaced.ephemeral = false;
  services.github-runners.spaced.workDir = "/data/runner_workspace";
  services.github-runners.spaced.extraPackages = with pkgs; [
    nodejs_24
    config.virtualisation.docker.package
    ccache
    jq
  ];
  services.github-runners.spaced.serviceOverrides = {
    ProtectHome = false;
    ReadWritePaths = [
      "/data/ccache"
      "/data/runner_workspace"
    ];
  };
  services.ollama = {
    enable = true;
    host = "0.0.0.0";
    loadModels = [ ];
    models = "/mnt/nvme/ai/ollama/models";
    package = pkgs.latest.ollama-vulkan;
  };
  services.caddy = {
    enable = true;
    virtualHosts.":11435" = {
      extraConfig = ''
        reverse_proxy http://192.168.223.107:11434
      '';
    };
  };

  system.stateVersion = "25.11";
  system.autoUpgrade = {
    enable = true;
    flake = inputs.self.outPath;
    flags = [
      "-L" # print build logs
      "--update-input"
      "latest"
      "--commit-lock-file"
    ];
    dates = "06:00";
  };

  time.timeZone = "Europe/Amsterdam";

  unfree.enable = true;
  unfree.packages = [
    "steam"
    "steam-unwrapped"
    "vintagestory"
    # "cuda_cudart"
    # "cuda_nvcc"
    # "cuda_cccl"
    # "libcublas"
  ];

  # Don't forget to set a password with ‘passwd’.
  user.enable = true;
  user.username = "koen";
  user.extraGroups = [
    "dialout"
    "networkmanager"
    "wheel"
  ];
}
