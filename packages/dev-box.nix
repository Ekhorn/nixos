{ pkgs }:

let
  omz_theme = import ./omz-theme.nix pkgs;

  zed-deps = with pkgs; [
    stdenv.cc.cc
    zlib
    openssl
    curl
    libgcc
  ];

  nixbldUserNames = builtins.concatStringsSep "," (
    map (n: "nixbld${toString n}") (pkgs.lib.range 1 10)
  );
  nixbldUsers = builtins.concatStringsSep "\n" (
    map (n: "nixbld${toString n}:x:${toString (30000 + n)}:30000:${toString n}:/var/empty:/bin/sh") (
      pkgs.lib.range 1 10
    )
  );

  groups = pkgs.writeTextDir "etc/group" ''
    root:x:0:
    sshd:x:100:
    nixbld:x:30000:${nixbldUserNames}
  '';
  users = pkgs.writeTextDir "etc/passwd" ''
    root:x:0:0:root:/root:/bin/zsh
    sshd:x:100:100:SSH Daemon:/var/empty:/bin/nologin
    ${nixbldUsers}
  '';
  passwd = pkgs.writeTextDir "etc/shadow" ''
    root::19000:0:99999:7:::
  '';

  zshrc = pkgs.writeTextDir "etc/zshrc" ''
    export ZSH="${pkgs.oh-my-zsh}/share/oh-my-zsh"
    export ZSH_CUSTOM="${omz_theme}"

    # Oh-my-zsh tries to write to $ZSH/cache. We must redirect it to a writable location.
    export ZSH_CACHE_DIR="/tmp/oh-my-zsh-cache"
    mkdir -p "$ZSH_CACHE_DIR"

    plugins=(git direnv)
    ZSH_THEME="robbyrussell+"
    source $ZSH/oh-my-zsh.sh

    setopt autocd
    autoload -U compinit && compinit
    source ${pkgs.zsh-autosuggestions}/share/zsh-autosuggestions/zsh-autosuggestions.zsh
    source ${pkgs.zsh-syntax-highlighting}/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
  '';

  nix_conf = pkgs.writeTextDir "etc/nix/nix.conf" ''
    experimental-features = nix-command flakes
  '';

  git = "${pkgs.gitMinimal}/bin/git";

  dev-box-image = pkgs.dockerTools.buildLayeredImage {
    name = "dev-box";
    tag = "latest";
    contents = [
      pkgs.busybox
      pkgs.dockerTools.caCertificates
      pkgs.fd
      pkgs.gitMinimal
      pkgs.nix
      pkgs.nix-ld
      pkgs.openssh
      pkgs.ripgrep
      pkgs.zsh
      pkgs.oh-my-zsh
      pkgs.direnv
      omz_theme
      # Configurations
      groups
      users
      passwd
      zshrc
      nix_conf
    ];
    config = {
      Cmd = [
        "${pkgs.zsh}/bin/zsh"
        "-c"
        ''
          mkdir -m 1777 -p /tmp
          mkdir -p /usr /etc/ssh /var/empty /root/.ssh
          ln -s /bin /usr/bin

          if [ ! -f /root/.ssh/ssh_host_ed25519_key ]; then
            ${pkgs.openssh}/bin/ssh-keygen -t ed25519 -f /root/.ssh/ssh_host_ed25519_key -N "" -q
          fi

          cat <<EOF > /etc/ssh/sshd_config
            Port 2222
            HostKey /root/.ssh/ssh_host_ed25519_key
            PermitRootLogin yes
            PermitEmptyPasswords yes
            PasswordAuthentication yes
            AuthenticationMethods none
            Subsystem sftp ${pkgs.openssh}/libexec/sftp-server
            ChrootDirectory none # Ensure we start in /root
            SetEnv NIXPKGS_ALLOW_UNFREE=1
          EOF

          exec ${pkgs.openssh}/bin/sshd -D -e
        ''
      ];
      Env = [
        "NIX_LD=${pkgs.nix-ld}/bin/nix-ld"
        "NIX_LD_LIBRARY_PATH=${pkgs.lib.makeLibraryPath zed-deps}"
        "HOME=/root"
      ];
    };
  };

  dev-box-script = pkgs.writeShellScriptBin "dev-box" ''
    IMAGE_PATH="${dev-box-image}"
    VOL_NAME="dev-box-data"
    CLEAN_FIRST=false

    for arg in "$@"; do
      case $arg in
        --clean) CLEAN_FIRST=true ;;
        *) ;;
      esac
    done

    # Resolve the host git repository (if any) before touching docker.
    # Inside one: the project lives in the container at /root/<clone name>.
    git_root=$(${git} rev-parse --show-toplevel 2>/dev/null) || git_root=""

    if [ "$CLEAN_FIRST" = true ]; then
      docker rm -f dev-box 2>/dev/null || true
      docker volume rm $VOL_NAME 2>/dev/null || true
      ssh-keygen -R "[localhost]:2222" 2>/dev/null || true
    fi

    docker rm -f dev-box > /dev/null || true
    docker rmi dev-box:latest > /dev/null || true

    docker load < "$IMAGE_PATH" > /dev/null
    docker volume create $VOL_NAME > /dev/null

    docker run -d --name dev-box -h dev-box -p 2222:2222 -v $VOL_NAME:/root dev-box:latest > /dev/null

    # Wait for container to be ready
    while ! docker exec dev-box true 2>/dev/null; do sleep 0.1; done

    if [ -z "$git_root" ]; then
      echo "Not inside a git repository; not opening zed."
      exit 0
    fi

    project_dir=$(${git} -C "$git_root" project-dir)

    if ! docker exec dev-box test -d "$project_dir"; then
      repo_url=$(${git} -C "$git_root" remote get-url origin 2>/dev/null) || repo_url=""
      if [ -n "$repo_url" ]; then
        docker exec dev-box git clone "$repo_url" "$project_dir" || echo "Clone failed; will open /root instead." >&2
      else
        echo "No 'origin' remote for $git_root; cannot clone into the container." >&2
      fi
    fi

    sleep 1 # Wait for SSH to be ready

    if ! docker exec dev-box test -d "$project_dir"; then
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
  name = "dev-box-package";
  paths = [ dev-box-script ];
}
