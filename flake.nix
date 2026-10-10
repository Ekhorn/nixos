{
  description = "My NixOS config";
  inputs = {
    stable.url = "github:NixOS/nixpkgs/nixos-26.05";
    unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
    latest.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "stable";
    };
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "stable";
    };
    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      inputs.nixpkgs.follows = "unstable";
    };
    microvm = {
      url = "github:microvm-nix/microvm.nix";
      inputs.nixpkgs.follows = "stable";
    };
    nix-flatpak.url = "github:gmodena/nix-flatpak/?ref=v0.7.0";
    nixos-hardware.url = "github:NixOS/nixos-hardware/72674a6b5599e844c045ae7449ba91f803d44ebc";
  };

  outputs =
    {
      self,
      stable,
      unstable,
      latest,
      home-manager,
      disko,
      microvm,
      ...
    }@inputs:
    let
      inherit (self) outputs;

      # Using nixpkgs.lib.systems.flakeExposed systems,
      # see https://github.com/NixOS/nixpkgs/blob/5d65a618c663db71662a434a3d5887f2ee7f0a1f/lib/systems/flake-systems.nix
      forAllSystems = f: builtins.mapAttrs f stable.legacyPackages;
      unsupported_systems = [
        # Tier 3
        "armv6l-linux"
        "armv7l-linux"
        "i686-linux"
        # Tier 6
        "powerpc64le-linux"
        # Unknown
        "riscv64-linux"
      ];
      isUnsupported = system: builtins.any (s: system == s) unsupported_systems;

      mkAnywhere =
        configuration: device:
        stable.lib.nixosSystem {
          modules = [
            configuration
            {
              disko.devices.disk.main.device = if device != null then device else "/dev/vda";
            }
          ];
          specialArgs = { inherit inputs outputs; };
        };
      mkNixos =
        configuration: overlays:
        stable.lib.nixosSystem {
          modules = [
            configuration
            {
              nixpkgs.overlays = import overlays { inherit inputs; };
              # Let 'nixos-version --json' know about the Git revision of this flake.
              # Ref https://www.tweag.io/blog/2020-07-31-nixos-flakes/#hermetic-evaluation
              system.configurationRevision = stable.lib.mkIf (self ? rev) self.rev;
            }
          ];
          specialArgs = {
            util = import ./lib/util.nix { inherit (stable) lib; };
            inherit inputs outputs;
          };
        };
      mkPi =
        configuration: overlays:
        mkNixos {
          imports = [
            configuration
            inputs.nixos-hardware.nixosModules.raspberry-pi-4
          ];
        } overlays;
      mkShell = file: pkgs: import file { inherit pkgs; };

      mkVmRunner = import ./lib/vm-runner.nix { inherit (stable) lib; };
    in
    {
      apps = forAllSystems (
        system: pkgs:
        pkgs.lib.optionalAttrs pkgs.stdenv.isLinux {
          dev-box = {
            type = "app";
            program = "${self.packages.${system}.dev-box}/bin/dev-box";
          };
        }
        // pkgs.lib.optionalAttrs (pkgs.stdenv.isLinux && !isUnsupported system) {
          dev-vm = {
            type = "app";
            program = "${self.packages.${system}.dev-vm}/bin/dev-vm";
          };
        }
      );

      formatter = forAllSystems (system: pkgs: pkgs.nixfmt-rs);

      devShells = forAllSystems (
        system: pkgs:
        pkgs.lib.optionalAttrs (!isUnsupported system && system != "x86_64-freebsd") {
          default = mkShell ./shells/default.nix pkgs;
          playwright = mkShell ./shells/playwright.nix pkgs;
          openremote = mkShell ./shells/openremote.nix pkgs;
        }
      );

      homeManagerModules = import ./modules/home-manager;

      nixosConfigurations = {
        emu = mkNixos ./hosts/emu/configuration.nix ./overlays;
        laptop-koen = mkNixos ./hosts/laptop-koen/configuration.nix ./overlays;
        pc-koen = mkNixos ./hosts/pc-koen/configuration.nix ./overlays;
        toshiba = mkNixos ./hosts/toshiba/configuration.nix ./overlays;
        pi = mkPi ./hosts/pi/configuration.nix ./overlays;
        main = mkAnywhere ./hosts/anywhere/main/configuration.nix "/dev/sda";
        spaced = mkAnywhere ./hosts/anywhere/spaced/configuration.nix "/dev/sda";
        anywhere = mkAnywhere ./hosts/anywhere/template/configuration.nix "/dev/sda";
      };

      nixosModules = import ./modules/nixos;

      packages = forAllSystems (
        system: pkgs:
        (pkgs.lib.optionalAttrs pkgs.stdenv.isLinux (
          builtins.mapAttrs (host: mkVmRunner system pkgs) self.nixosConfigurations
        ))
        // pkgs.lib.optionalAttrs pkgs.stdenv.isLinux {
          dev-box = import ./packages/dev-box.nix { inherit pkgs; };
        }
        // pkgs.lib.optionalAttrs (pkgs.stdenv.isLinux && !isUnsupported system) {
          dev-vm = import ./packages/dev-vm.nix {
            inherit pkgs system microvm;
            nixosSystem = stable.lib.nixosSystem;
          };
        }
      );
    };
}
