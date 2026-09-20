{
  pkgs,
  system,
  microvm,
  nixosSystem,
}:

let
  omz_theme = import ./omz-theme.nix pkgs;

  zed-deps = with pkgs; [
    stdenv.cc.cc
    zlib
    openssl
    curl
    libgcc
  ];

  dev-vm = nixosSystem {
    inherit system;
    modules = [
      microvm.nixosModules.microvm
      {
        networking.hostName = "dev-vm";

        microvm = {
          hypervisor = "qemu";
          mem = 8192; # 8GB
          vcpu = 4;
          volumes = [
            {
              mountPoint = "/root";
              image = "dev-vm-root.img";
              size = 20480; # 20GB
            }
            {
              mountPoint = "/nix/store-writable";
              image = "nix-store-writable.img";
              size = 20480; # 20GB
            }
          ];
          shares = [
            {
              source = "/nix/store";
              mountPoint = "/nix/.ro-store";
              tag = "ro-store";
              proto = "9p";
            }
          ];
          interfaces = [
            {
              type = "user";
              id = "qemu";
              mac = "02:00:00:00:00:01";
            }
          ];
          forwardPorts = [
            {
              from = "host";
              host.port = 2222;
              guest.port = 22;
            }
          ];
        };

        environment.systemPackages = with pkgs; [
          busybox
          fd
          gitMinimal
          htop
          nix
          nix-ld
          ripgrep
          zsh
          direnv
        ];

        programs.nix-ld.enable = true;
        programs.nix-ld.libraries = zed-deps;

        systemd.tmpfiles.rules = [
          "d /root/.ssh 0700 root root - -"
        ];

        services.openssh = {
          enable = true;
          hostKeys = [
            {
              type = "ed25519";
              path = "/root/.ssh/ssh_host_ed25519_key";
            }
          ];
          settings = {
            PermitRootLogin = "yes";
            PermitEmptyPasswords = "yes";
            PasswordAuthentication = true;
            UsePAM = false;
          };
          extraConfig = ''
            AuthenticationMethods none
            ChrootDirectory none
            SetEnv NIXPKGS_ALLOW_UNFREE=1
          '';
        };

        programs.zsh = {
          enable = true;
          ohMyZsh = {
            enable = true;
            theme = "robbyrussell+";
            custom = "${omz_theme}";
            plugins = [
              "git"
              "direnv"
            ];
          };
          interactiveShellInit = ''
            export ZSH_CACHE_DIR="/tmp/oh-my-zsh-cache"
            mkdir -p "$ZSH_CACHE_DIR"
            source ${pkgs.zsh-autosuggestions}/share/zsh-autosuggestions/zsh-autosuggestions.zsh
            source ${pkgs.zsh-syntax-highlighting}/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
          '';
        };
        users.users.root = {
          shell = pkgs.zsh;
          hashedPassword = ""; # empty password to unlock the account
        };

        # Rootful docker. The microvm gives root full kernel capabilities
        # (cgroups, iptables, /sys/fs/cgroup) so the standard daemon works.
        # The VM's `/` is an in-RAM rootfs (~4G, volatile), so we must point
        # docker's data-root at the persistent writable /root volume
        # (dev-vm-root.img, 10GB) — otherwise every image pull fills RAM
        # and is lost on reboot.
        virtualisation.docker = {
          enable = true;
          storageDriver = "overlay2";
          daemon.settings.data-root = "/root/docker-data";
        };

        nix.settings = {
          experimental-features = [
            "nix-command"
            "flakes"
          ];
          store = "/nix/store-writable";
        };

        system.stateVersion = "26.05";
      }
    ];
  };

  runner = dev-vm.config.microvm.declaredRunner;

  git = "${pkgs.gitMinimal}/bin/git";
  ssh = "${pkgs.openssh}/bin/ssh";
  sshKeygen = "${pkgs.openssh}/bin/ssh-keygen";
  setsid = "${pkgs.util-linux}/bin/setsid";

  dev-vm-script = pkgs.writeShellScriptBin "dev-vm" ''
    # All VM state (disk images, pid file, log) lives in one fixed place so
    # dev-vm can be started from any directory.
    STATE_DIR="$HOME/.local/share/dev-vm"
    PID_FILE="$STATE_DIR/vm.pid"
    LOG_FILE="$STATE_DIR/vm.log"

    vm_ssh() {
      ${ssh} -o BatchMode=yes -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o LogLevel=ERROR -p 2222 root@localhost "$@"
    }

    vm_running() {
      vm_ssh true 2>/dev/null
    }

    stop_vm() {
      stopped=false
      if vm_running; then
        echo "Stopping dev-vm..."
        vm_ssh poweroff >/dev/null 2>&1 || true
        tries=0
        while vm_running; do
          tries=$((tries + 1))
          if [ "$tries" -gt 60 ]; then
            break
          fi
          sleep 0.5
        done
        stopped=true
      fi
      if [ -f "$PID_FILE" ]; then
        pid=$(cat "$PID_FILE")
        rm -f "$PID_FILE"
        # Only kill if the pid still belongs to the VM (guard against a
        # stale pid file whose pid was reused by an unrelated process).
        if [ -n "$pid" ] && kill -0 "$pid" 2>/dev/null && grep -qaz -e qemu -e microvm "/proc/$pid/cmdline" 2>/dev/null; then
          echo "Force-stopping dev-vm process group $pid..."
          kill -TERM -- -"$pid" 2>/dev/null || kill -TERM "$pid" 2>/dev/null || true
          stopped=true
        fi
      fi
      if [ "$stopped" = true ]; then
        echo "dev-vm stopped."
      else
        echo "dev-vm is not running."
      fi
    }

    case "$1" in
      stop)
        stop_vm
        exit 0
        ;;
      --clean)
        if vm_running; then
          echo "dev-vm is running. Stop it first with: dev-vm stop" >&2
          exit 1
        fi
        echo "Removing dev-vm disk images..."
        rm -f "$STATE_DIR"/dev-vm-root.img "$STATE_DIR"/nix-store-writable.img
        # The VM's ssh host key lives on the wiped root volume, so the next
        # boot generates a new one. Drop the stale known_hosts entry so zed's
        # ssh doesn't complain about a changed host key.
        ${sshKeygen} -R "[localhost]:2222" 2>/dev/null || true
        ;;
      "")
        ;;
      *)
        echo "Usage: dev-vm [--clean] | dev-vm stop" >&2
        exit 1
        ;;
    esac

    mkdir -p "$STATE_DIR"

    # Resolve the host git repository before anything changes directory.
    # Inside one: make sure the project exists on the VM at /root/<repo dir
    # name>, cloning from the origin remote if needed.
    git_root=$(${git} rev-parse --show-toplevel 2>/dev/null) || git_root=""

    if vm_running; then
      echo "dev-vm is already running."
    else
      echo "Starting dev-vm in the background (log: $LOG_FILE)..."
      cd "$STATE_DIR"
      # Detach into a new session so the VM survives the terminal closing.
      ${setsid} ${runner}/bin/microvm-run >"$LOG_FILE" 2>&1 </dev/null &
      echo $! > "$PID_FILE"

      tries=0
      until vm_running; do
        if ! kill -0 "$(cat "$PID_FILE")" 2>/dev/null; then
          echo "dev-vm failed to start, see $LOG_FILE" >&2
          exit 1
        fi
        tries=$((tries + 1))
        if [ "$tries" -gt 120 ]; then
          echo "Timed out waiting for dev-vm SSH, see $LOG_FILE" >&2
          exit 1
        fi
        sleep 0.5
      done
      echo "dev-vm is up."
    fi

    if [ -z "$git_root" ]; then
      echo "Not inside a git repository; not opening zed."
      exit 0
    fi

    project_dir=$(${git} -C "$git_root" project-dir)

    if ! vm_ssh "test -d '$project_dir'"; then
      repo_url=$(${git} -C "$git_root" remote get-url origin 2>/dev/null) || repo_url=""
      if [ -n "$repo_url" ]; then
        vm_ssh "git clone '$repo_url' '$project_dir'" || echo "Clone failed; will open /root instead." >&2
      else
        echo "No 'origin' remote for $git_root; cannot clone into the VM." >&2
      fi
    fi

    if ! vm_ssh "test -d '$project_dir'"; then
      project_dir="/root"
    fi

    zed_cmd=$(command -v zeditor) || zed_cmd=""
    if [ -n "$zed_cmd" ]; then
      "$zed_cmd" "ssh://root@localhost:2222$project_dir" >/dev/null 2>&1 &
    else
      echo "zeditor not found in PATH." >&2
    fi
  '';
in
pkgs.symlinkJoin {
  name = "dev-vm-package";
  paths = [ dev-vm-script ];
}
