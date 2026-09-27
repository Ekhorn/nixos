{ config, pkgs, ... }:

let
  omz_theme = import ../../packages/omz-theme.nix pkgs;
in
{
  programs.zsh = {
    enable = true;

    autocd = true;
    autosuggestion.enable = true;
    dotDir = "${config.home.homeDirectory}/.config/zsh";
    enableCompletion = true;
    history.ignoreSpace = false;
    syntaxHighlighting.enable = true;

    shellAliases = {
      build = "nixos-rebuild build";
      update = "sudo nixos-rebuild switch --recreate-lock-file";
      switch = "sudo nixos-rebuild switch";
      test = "sudo nixos-rebuild test";
      ta = "tmux attach";
      zed = "zeditor";
      dbd = "dev-box-diff";
    };

    initContent =
      let
        guestDiffCmd = colorize: ''git --no-pager -C \"$project_dir\" diff --color=${colorize}'';
      in
      ''
        build-vm() {
          (cd "''${$(readlink -f /etc/nixos/flake.nix)%/*}" && nix build .#$1 && ./result/bin/run-$1-vm)
        }
        dev() {
          SHELL=$(which zsh) nix develop $(readlink -f /etc/nixos/flake.nix)#$1 --command zsh
        }
        clean() {
          # https://github.com/NixOS/nix/issues/8508#issuecomment-2808614321
          user_profiles_garbage="/run/current-system/sw/bin/nix-collect-garbage"
          if [ -z "$1" ]; then
            sudo nix-collect-garbage -d
            "$user_profiles_garbage" -d
          else
            sudo nix-collect-garbage --delete-older-than "$1"
            "$user_profiles_garbage" --delete-older-than "$1"
          fi
        }
        dev-box-diff() {
          local git_root project_dir
          if ! git_root=$(git rev-parse --show-toplevel 2>/dev/null); then
            echo "dbd: not inside a git repository" >&2
            return 1
          fi
          project_dir=$(git -C "$git_root" project-dir)
          if [ -t 1 ]; then
            ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o LogLevel=ERROR \
                -p 2222 root@localhost "${guestDiffCmd "always"}" "$@" | less -R
          else
            ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o LogLevel=ERROR \
                -p 2222 root@localhost "${guestDiffCmd "never"}" "$@"
          fi
        }
        gradle() {
          local git_root
          if git_root=$(git rev-parse --show-toplevel 2>/dev/null); then
            if [[ -x "$git_root/gradlew" ]]; then
              echo "Using repo gradlew ($git_root/gradlew)"
              "$git_root/gradlew" "$@"
              return
            fi
          fi
          # Fallback: Use the system-wide gradle command if not in a repo
          # or if gradlew doesn't exist.
          # 'command' prevents an infinite loop of calling this function.
          command gradle "$@"
        }
        stash-clean() {
          local -a lines
          local text ref hash subject entry choice

          # ref (%gd), hash (%H), subject (%gs)
          text="$(git stash list --format='%gd %H %gs')"
          [[ -z $text ]] && {
            print "No stashes."
            return 0
          }

          lines=(''${(Oa)''${(f)text}}) # reverse

          for entry in "''${lines[@]}"; do
            read -r ref hash subject <<< "$entry"
            printf '\033[H\033[J' # Home cursor, Clear to bottom

            if {
              print "$ref: $subject\n"
              git --no-pager stash show --patch --color=always "$hash"
            } | LESSKEY_CONTENT=$'#command\nd quit d\nn quit n\nq quit q' \
                less -XR -P'[d]rop  [n]ext  [q]uit'
            then
              choice=0
            else
              choice=$?
            fi

            case $choice in
              100) git stash drop "$ref" || return 1 ;; # d
              110) continue ;;                          # n
              113) return 0 ;;                          # q
              *)   print -u2 "Pager failed ($choice)."; return 1 ;;
            esac
          done
        }
        docker-host-access-toggle() {
          local var="DOCKERD_ROOTLESS_ROOTLESSKIT_DISABLE_HOST_LOOPBACK"

          if [[ "$(systemctl --user show-environment)" == *"$var"* ]]; then
            systemctl --user unset-environment "$var"
            echo "Disabling host loop back"
          else
            systemctl --user set-environment "$var=false"
            echo "Enabling host loop back"
          fi

          systemctl --user restart docker
        }
      '';

    oh-my-zsh = {
      enable = true;
      theme = "robbyrussell+";
      custom = "${omz_theme}";
      plugins = [
        "colored-man-pages"
        "deno"
        "direnv"
        "docker"
        # "doctl"
        "gh"
        "kubectl"
        "podman"
        "rust"
        "ssh"
      ];
    };
  };
}
