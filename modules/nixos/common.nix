{
  config,
  inputs,
  outputs,
  pkgs,
  util,
  ...
}:

{
  imports = [
    ../shared/unfree.nix
  ];

  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.systemd-boot.enable = true;

  environment.systemPackages =
    with pkgs;
    [
      alacritty
      bluez
      gnupg
      nautilus
      parted
    ]
    ++ [ outputs.packages.${pkgs.stdenv.hostPlatform.system}.dev-vm ];
  environment.variables.NODEJS_PATH = "${pkgs.nodejs}/";

  fonts.packages = with pkgs; [
    nerd-fonts.symbols-only
    noto-fonts
    ubuntu-classic
  ];

  hardware.bluetooth.enable = true;
  hardware.graphics.enable = true;
  hardware.graphics.enable32Bit = true;

  home-manager.extraSpecialArgs = { inherit inputs outputs util; };

  i18n.defaultLocale = "en_US.UTF-8";
  i18n.extraLocaleSettings = {
    LC_ADDRESS = "nl_NL.UTF-8";
    LC_IDENTIFICATION = "nl_NL.UTF-8";
    LC_MEASUREMENT = "nl_NL.UTF-8";
    LC_MONETARY = "nl_NL.UTF-8";
    LC_NAME = "nl_NL.UTF-8";
    LC_NUMERIC = "nl_NL.UTF-8";
    LC_PAPER = "nl_NL.UTF-8";
    LC_TELEPHONE = "nl_NL.UTF-8";
    LC_TIME = "nl_NL.UTF-8";
  };

  nix.settings = {
    experimental-features = [
      "nix-command"
      "flakes"
    ];
  };

  programs.dconf.enable = true;
  programs.direnv.enable = true;
  programs.gnupg = {
    agent.enable = true;
    agent.pinentryPackage = pkgs.pinentry-gnome3;
  };
  programs.nautilus-open-any-terminal = {
    enable = true;
    terminal = "alacritty";
  };
  programs.zsh.enable = true;

  # security.pam.services.login.enableGnomeKeyring = true;
  security.polkit.enable = true;
  security.rtkit.enable = true;

  services.avahi = {
    enable = true;
    nssmdns4 = true;
    openFirewall = true;
  };
  services.fwupd.enable = true;
  services.gnome.gcr-ssh-agent.enable = true;
  services.gvfs.enable = true;
  services.logind.settings.Login = {
    HandlePowerKey = "ignore";
  };
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    wireplumber.enable = true;
  };
  services.printing.enable = true;
  services.syncthing = {
    enable = true;
    user = config.user.username;
    configDir = "/home/${config.user.username}/.local/state/syncthing";
  };

  unfree.enable = true;
  unfree.packages = [
    "discord"
    "idea"
    "obsidian"
  ];
}
