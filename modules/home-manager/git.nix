{ lib, ... }:

let
  # Git `!` alias idiom: define and immediately call a shell function.
  gitFn = body: "!f() { ${body} }; f";
  gitOp =
    action:
    gitFn ''
      repo=$(git rev-parse --git-dir);
      for file in rebase-merge rebase-apply MERGE_HEAD CHERRY_PICK_HEAD REVERT_HEAD AM_HEAD; do
        [ -e "$repo/$file" ] && { cmd="''${file%[-_]*}"; cmd="''${cmd,,}"; git ''${cmd//_/-} --${action}; break; }
      done;
    '';

  format = "%C(yellow)%h%Creset %Cgreen%cr%Creset %Cblue%an%Creset%C(auto)%d%Creset %s";
  merge-base = "git merge-base origin HEAD";
in
{
  programs.git = {
    enable = true;
    lfs.enable = true;
    settings = {
      alias = {
        amend = "commit --amend --no-edit";
        clear = "!git restore . && git clean -fd";
        ls = "log --stat --pretty=format:'${format}'";
        lsd = "!git log --stat --pretty=format:'${format}' $(${merge-base})..HEAD";
        sum = "!git diff --oneline --stat $(${merge-base})..HEAD";
        count = gitFn ''base=''${1:-$(''${merge-base})}; echo " $(git rev-list --count $base..HEAD) commits";'';
        pop-untracked = ''!git diff --binary "stash@{0}^2" "stash@{0}" | git apply && git stash drop "stash@{0}"'';
        stash-untracked = "stash push --keep-index";
        view-stash = gitFn ''
          text="$(git stash list --format='%gd %H %gs')";
          [ -z "$text" ] && { printf 'No stashes.\n'; return 0; };
          printf '%s\n' "$text" | tac | while read -r ref hash subject; do
            printf '\033[H\033[J';
            if { printf '%s: %s\n' "$ref" "$subject"; git --no-pager stash show --patch --color=always "$hash"; } |
               LESSKEY_CONTENT="$(printf '#command\nd quit d\nn quit n\nq quit q')" less -XR -P'[d]rop  [n]ext  [q]uit'; then
              choice=0;
            else
              choice=$?;
            fi;
            case $choice in
              100) git stash drop "$ref" || exit 1 ;;
              110) continue ;;
              113) exit 0 ;;
              *)   printf 'Pager failed (%s).\n' "$choice" >&2; exit 1 ;;
            esac;
          done;
        '';
        project-dir = gitFn ''
          name=$(basename "$(git remote get-url origin 2>/dev/null)" .git);
          name=''${name:-$(basename "$(git rev-parse --show-toplevel 2>/dev/null)")};
          echo "/root/$name";
        '';
        replace-from = gitFn ''
          git fetch "ssh://root@localhost:2222/$(git project-dir)" &&
          git range-diff '@...FETCH_HEAD' && \
          printf "Replace current branch? [y/N] " &&
          read answer &&
          case "$answer" in
            y|Y) git reset --hard FETCH_HEAD ;;
          esac;
        '';
      }
      // (lib.genAttrs [ "abort" "continue" "quit" ] gitOp);
      core.editor = "hx";
      credential.helper = "store";
      format.commitMessageColumns = 72;
      init.defaultBranch = "main";
      push.autoSetupRemote = true;
      user.email = "koen@kschellingerhout.nl";
      user.name = "Ekhorn";
    };
    signing.key = "koen@kschellingerhout.nl";
    signing.signByDefault = true;
  };
}
