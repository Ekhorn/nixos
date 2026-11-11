{ lib, pkgs, ... }:

let
  user = "test";
in
{
  # vmVariant depends on: https://github.com/NixOS/nixpkgs/blob/nixos-25.11/nixos/modules/virtualisation/qemu-vm.nix
  # default qemu: options are set here https://github.com/NixOS/nixpkgs/blob/nixos-25.11/nixos/lib/qemu-common.nix
  virtualisation.vmVariant = {
    virtualisation = {
      cores = 4;
      memorySize = 4096; # 2048; # 8192;
      qemu.options =
        # Acceleration (KVM with TCG fallback), CPU and machine type defaults
        # are set by nixpkgs' qemu-common based on the host running the VM.
        # q35 and virtio-vga-gl are x86-only; aarch64 gets virt via qemu-common
        # and uses virtio-gpu-gl-pci for GL instead.
        lib.optionals pkgs.stdenv.hostPlatform.isx86 [
          "-machine q35"
          "-device virtio-vga-gl"
        ]
        ++ lib.optionals pkgs.stdenv.hostPlatform.isAarch64 [ "-device virtio-gpu-gl-pci" ]
        ++ [
          "-device virtio-balloon"
          "-device virtio-rng-pci,rng=rng0"
          "-display gtk,gl=on,grab-on-hover=on,show-cursor=on,zoom-to-fit=on"
          "-object rng-random,id=rng0,filename=/dev/urandom"
          # "-nographic"
        ];

      forwardPorts = [
        {
          from = "host";
          host.port = 10022;
          guest.port = 22;
        }
      ];
    };

    # Guest user
    users.users.guest = {
      group = "guest";
      initialPassword = "guest";
      isSystemUser = true;
      shell = pkgs.zsh;
    };
    users.groups.guest = { };

    # Essential overwrites
    user.username = lib.mkVMOverride user;
    users.users.${user} = {
      initialPassword = lib.mkVMOverride "test";
    };
    home-manager.users.test.home.username = lib.mkVMOverride user;

    # Non-essential overwrites
    services.avahi.enable = lib.mkVMOverride false;
    services.ollama.enable = lib.mkVMOverride false;
    services.printing.enable = lib.mkVMOverride false;

    services.openssh.settings = {
      AllowUsers = lib.mkVMOverride null;
    };

    system.autoUpgrade.enable = lib.mkVMOverride false;
  };
}
