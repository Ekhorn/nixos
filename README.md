# NixOS Configuration

### Minimal Installation

Based on <https://nixos.org/manual/nixos/stable/#sec-installation-manual>

```sh
sudo -i
```

<details>
  <summary>Configure wifi</summary>

```sh
sudo systemctl start wpa_supplicant
```

```sh
wpa_cli
0
set_network 0 ssid "network"
OK
set_network 0 psk "password"
OK
enable_network 0
OK
quit
```

</details>

**UEFI (GPT)**

```sh
parted /dev/disk1 -- mklabel gpt
parted /dev/disk1 -- mkpart root ext4 512MB -8GB
parted /dev/disk1 -- mkpart ESP fat32 1MB 512MB
parted /dev/disk1 -- set 2 esp on
```

**(Optional) LUKS Setup**

```sh
cryptsetup luksFormat /dev/disk1part1
cryptsetup luksOpen /dev/disk1part1 crypted
mkfs.ext4 /dev/mapper/crypted
```

**Formatting**

```sh
mkfs.ext4 -L nixos /dev/disk1part1 # Skip when using LUKS
mkfs.fat -F 32 -n boot /dev/disk1part2
```

**Installing**

```sh
mount /dev/disk/by-label/nixos /mnt # No LUKS
mount /dev/mapper/crypted /mnt # LUKS
mkdir -p /mnt/boot
mount -o umask=077 /dev/disk/by-label/boot /mnt/boot
```

```sh
nixos-generate-config --root /mnt
```

Configure `hostname`, enable `networking.networkmanager.enable`, set `user` with package `git` and save.

```sh
nano /mnt/etc/nixos/configuration.nix
```

Install nixos

```sh
nixos-install
```

Set user password and reboot.

```sh
nixos-enter --root /mnt -c 'passwd user'
reboot
```

### Setup

Assuming the repo is cloned (use `nmtui` for wifi).

```sh
cd develop/nixos
```

Copy the hardware configuration to the host directory.

```sh
cp /etc/nixos/hardware-configuration.nix hosts/my-host
```

Wipe the old nixos configuration.

```sh
sudo rm -rf /etc/nixos/*
```

Symlink new configuration.

```sh
sudo ln -s $(pwd)/flake.nix /etc/nixos/flake.nix
```

Lastly, rebuild the nixos configuration and reboot.

```sh
sudo nixos-rebuild switch .#my-host
reboot
```

### Post-install Secrets Configuration

Update password manager.

```sh
keepassxc ~/Desktop/$USER.kdbx
```

Create and add new ssh key.

```sh
ssh-keygen
cat ~/.ssh/id_*.pub >> modules/nixos/authorized_keys
git commit -m "conf: add authorized public key" --no-gpg-sign
```

Or when reusing a key.

```sh
ssh-add .ssh/id_*
nix shell nixpkgs#libsecret
secret-tool store --label="Unlock password for id_*" unique ssh-store:$HOME/.ssh/id_*
```

Then copy GPG from other system, you may need to reboot the system.

```sh
ssh other@hostname 'gpg --export-secret-keys -a "$(gpg -K | rg -o "[A-F0-9]{40}")"' | gpg --import
gpg --edit-key "$(gpg -K | rg -o "[A-F0-9]{40}")"
seahorse
```

### Mounting drives

<!-- TODO: consider disko configs?? -->

List drives

```sh
lsblk -f -o NAME,UUID,FSTYPE,SIZE
```

Set drive to mount

```sh
hx hosts/new-host/hardware-configuration.nix
```

```nix
fileSystems."/mnt/hdd" =
  { device = "/dev/disk/by-uuid/uuid";
    fsType = "ext4";
  };
```

### Adding a swap file

Add the following to your `hardware-configuration.nix`.

```nix
  swapDevices = [
    {
      device = "/var/lib/swapfile";
      size = 64 * 1024; # 64GB
    }
```

### Troubleshooting

**Reformatting drive while still in hardware-config**

```sh
cat /etc/fstab # Expected paths
tune2fs -U <UUID> /dev/sdX
reboot
```

**Zed editor Java JDTLS oneshot error**

```sh
rm -r /tmp/jdtls-*
```

<details>
  <summary>Figured out through</summary>

```sh
strace -f -o trace.log zeditor --foreground .
cat trace.log | rg jdtls
```

</details>

### Deploying to a remote host

```sh
nixos-rebuild --target-host host --sudo switch --flake .#host --ask-sudo-password
```

#### Troubleshooting

If remote builds aren't working you can always copy the config to the remote
and build on the remote (potentially at the cost of a slower build).

```sh
sudo nixos-rebuild switch --flake .#host
```

### NixOS Anywhere

```sh
nix run github:nix-community/nixos-anywhere -- \
  --generate-hardware-config nixos-generate-config ./<configuration-name>/hardware-configuration.nix --no-substitute-on-destination \
  --flake .#<configuration-name> root@<ip address>
```

```sh
ssh user@<ip address>
ssh root@<ip address>
passwd user
```

```nix
  services.openssh = {
    enable = true;
    ports = [ 22 ];
    settings = {
      # PasswordAuthentication = false;
      # PermitRootLogin = "no";
      # UsePAM = false;
      # KbdInteractiveAuthentication = false;
    };
  };
```

```sh
nixos-rebuild --target-host user@ip-address --use-remote-sudo switch --flake .#<configuration-name>
```

### VMs

#### Resize disk

**Host**

```sh
sudo qemu-img resize /path/to/qemu/<vm-name>.qcow2 +10G
```

**Guest**

```sh
lsblk
sudo parted /dev/vda
> print
> resizepart 1 10GB
> quit
sudo resize2fs /dev/vda1
df -h
```

#### Troubleshooting

**After updating firmware**

Error: Unable to find 'efi' firmware that is compatible with the current version

Update the firmware path in the VM configuration.

<details>
  <summary>Find paths</summary>

```sh
fd secure-code /nix/store/
/nix/store/ddf1vssb23g4jbdivhfgwi0iaimpz7my-qemu-9.1.3/share/qemu/edk2-x86_64-secure-code.fd
/nix/store/ddf1vssb23g4jbdivhfgwi0iaimpz7my-qemu-9.1.3/share/qemu/edk2-i386-secure-code.fd
/nix/store/sq4s9m7n5nj6asjddbbr46wnxp42sxrg-qemu-9.1.2/share/qemu/edk2-x86_64-secure-code.fd
/nix/store/sq4s9m7n5nj6asjddbbr46wnxp42sxrg-qemu-9.1.2/share/qemu/edk2-i386-secure-code.fd
fd vars.fd /nix/store
/nix/store/ddf1vssb23g4jbdivhfgwi0iaimpz7my-qemu-9.1.3/share/qemu/edk2-arm-vars.fd
/nix/store/ddf1vssb23g4jbdivhfgwi0iaimpz7my-qemu-9.1.3/share/qemu/edk2-riscv-vars.fd
/nix/store/ddf1vssb23g4jbdivhfgwi0iaimpz7my-qemu-9.1.3/share/qemu/edk2-i386-vars.fd
/nix/store/sq4s9m7n5nj6asjddbbr46wnxp42sxrg-qemu-9.1.2/share/qemu/edk2-arm-vars.fd
/nix/store/sq4s9m7n5nj6asjddbbr46wnxp42sxrg-qemu-9.1.2/share/qemu/edk2-riscv-vars.fd
/nix/store/sq4s9m7n5nj6asjddbbr46wnxp42sxrg-qemu-9.1.2/share/qemu/edk2-i386-vars.fd
```

</details>
