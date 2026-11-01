{ config, ... }:

{
  boot.blacklistedKernelModules = [ "nouveau" ];
  boot.extraModprobeConfig = ''
    blacklist nouveau
    options nouveau modeset=0
  '';

  hardware = {
    nvidia = {
      modesetting.enable = true;
      powerManagement.enable = false;
      powerManagement.finegrained = false;
      open = false;
      package = config.boot.kernelPackages.nvidiaPackages.legacy_580;
    };
    nvidia-container-toolkit = {
      enable = false;
    };
  };

  # The only switch that turns `hardware.nvidia.enabled` on (it is readOnly and
  # derived from this). No X server is required — this just enables the kernel
  # driver + Vulkan ICD for the Wayland session.
  services.xserver.videoDrivers = [ "nvidia" ];

  unfree.enable = true;
  unfree.packages = [
    "nvidia-kernel-modules"
    "nvidia-settings"
    "nvidia-x11"
  ];
}
