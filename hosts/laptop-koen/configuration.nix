{
  config,
  inputs,
  lib,
  outputs,
  ...
}:

{
  imports = [
    ./hardware-configuration.nix
    inputs.home-manager.nixosModules.home-manager
  ]
  ++ (builtins.attrValues outputs.nixosModules);

  boot.binfmt.emulatedSystems = [ "aarch64-linux" ];

  hardware.bluetooth.powerOnBoot = false;

  home-manager = {
    backupFileExtension = "backup";
    useGlobalPkgs = true;
    useUserPackages = true;
    users.${config.user.username} = import ./home.nix;
  };

  networking.hostName = "laptop-koen";
  networking.networkmanager.enable = true;

  nixpkgs.overlays = [
    (final: prev: {
      displaylink = prev.displaylink.overrideAttrs (_: {
        src = prev.fetchurl {
          url = "https://www.synaptics.com/sites/default/files/exe_files/2025-09/DisplayLink%20USB%20Graphics%20Software%20for%20Ubuntu6.2-EXE.zip";
          hash = "sha256-JQO7eEz4pdoPkhcn9tIuy5R4KyfsCniuw6eXw/rLaYE=";
        };
      });
    })
  ];

  services.fprintd.enable = true;
  services.logind.settings.Login = {
    HandleLidSwitch = "hibernate";
    HandleLidSwitchExternalPower = "hibernate";
  };
  services.usbguard.enable = true;
  services.xserver.videoDrivers = [ "displaylink" ];

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

  systemd.services = {
    dlm.wantedBy = [ "multi-user.target" ];
    fprintd = {
      wantedBy = [ "multi-user.target" ];
      serviceConfig.Type = "simple";
    };
  };

  time.timeZone = "Europe/Amsterdam";

  unfree.enable = true;
  unfree.packages = [
    "displaylink"
    "slack"
  ];

  # Don't forget to set a password with ‘passwd’.
  user.enable = true;
  user.username = "koen";
}
