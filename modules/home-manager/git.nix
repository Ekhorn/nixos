{ lib, ... }:

let
  gitOp =
    action:
    "!f() { \
      repo=$(git rev-parse --git-dir); \
      for file in rebase-merge rebase-apply MERGE_HEAD CHERRY_PICK_HEAD REVERT_HEAD AM_HEAD; do \
        [ -e \"$repo/$file\" ] && { cmd=\"\${file%[-_]*}\"; cmd=\"\${cmd,,}\"; git \${cmd//_/-} --${action}; break; } \
      done; \
    }; f";
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
        ls = "log --stat --pretty=format:'%C(yellow)%h%Creset %Cgreen%cr%Creset %Cblue%an%Creset%C(auto)%d%Creset %s'";
        lsd = "!git log --stat --pretty=format:'%C(yellow)%h%Creset %Cgreen%cr%Creset %Cblue%an%Creset%C(auto)%d%Creset %s' $(${merge-base})..HEAD";
        sum = "!git diff --oneline --stat $(${merge-base})..HEAD";
        count = "!f() { base=\${1:-$(${merge-base})}; echo \" $(git rev-list --count $base..HEAD) commits\"; }; f";
        project-dir = "!f() { \
            name=$(basename \"$(git remote get-url origin 2>/dev/null)\" .git); \
            name=\${name:-$(basename \"$(git rev-parse --show-toplevel 2>/dev/null)\")}; \
            echo \"/root/$name\"; \
          }; f";
        replace-from = "!f() { \
           git fetch \"ssh://root@localhost:2222/\$(git project-dir)\" && \
            git range-diff '@{u}...FETCH_HEAD' \&\& \\
            printf \"Replace current branch? [y/N] \" && \
            read answer && \
            case \"\$answer\" in \
              y|Y) git reset --hard FETCH_HEAD ;; \
            esac; \
          }; f";
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
