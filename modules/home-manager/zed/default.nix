{ pkgs, lib, ... }:

let
  unattended = import ./skills/unattended.nix { inherit lib; };
in
{
  programs.zed-editor = {
    enable = true;
    mutableUserSettings = false;
    extensions = [
      "groovy"
      "java"
      "latex"
      "ltex"
      "mdx"
      "nix"
      "toml"
    ];
    package = pkgs.latest.zed-editor.overrideAttrs (old: {
      patches = (old.patches or [ ]) ++ [
        (pkgs.fetchpatch {
          name = "zed-openai-model-discovery.patch";
          url = "https://github.com/Ekhorn/zed/commit/fc445e998642b6d83ef2640f6f60093e9d1f8899.patch";
          hash = "sha256-HgWsi4ZMs7/3pz91IKJ6AAok7wix71icvetOO7Q46/I=";
        })
      ];
    });
    themes = {
      dark = ./theme.json;
    };
    mutableUserKeymaps = false; # setting to true is unreliable
    userKeymaps = import ./keymap.nix;
    userSettings = {
      auto_update = false;
      format_on_save = "off";

      ui_font_size = 14;
      buffer_font_size = 14;
      theme = {
        mode = "dark";
        light = "One Light";
        dark = "Zed Dark";
      };
      show_whitespaces = "all";
      soft_wrap = "editor_width";
      scrollbar = {
        axes = {
          horizontal = false;
        };
      };
      outline_panel = {
        button = false;
      };
      collaboration_panel = {
        button = false;
      };
      language_models = {
        ollama = {
          api_url = "http://pc-koen:32103";
          auto_discover = true;
        };
        openai_compatible = {
          gufo = {
            api_url = "http://pc-koen:32100/v1";
          };
        };
      };

      agent = {
        enable_feedback = false;
        show_turn_stats = true;
        sandbox_permissions = {
          allow_unsandboxed = true;
        };
        tool_permissions = {
          default = "confirm";
          tools = (import ./tools.nix { inherit lib; }).tools;
        };
      };

      languages = {
        Nix = {
          format_on_save = "on";
          language_servers = [
            "nil"
            "!nixd"
          ];
          formatter = {
            external = {
              command = "${pkgs.nixfmt-rs}/bin/nixfmt";
              arguments = [
                "--quiet"
                "--"
              ];
            };
          };
        };
      };

      lsp = {
        texlab = {
          settings = {
            texlab = {
              build = {
                onSave = true;
                forwardSearchAfter = true;
                executable = "pdflatex";
                args = [
                  "-synctex=1"
                  "-recorder"
                  "%f"
                ];
              };
              forwardSearch = {
                executable = "zathura";
                args = [
                  "--synctex-forward"
                  "%l:1:%f"
                  "-x"
                  "zed %%{input}:%%{line}"
                  "%p"
                ];
              };
            };
          };
        };
      };

    };
  };

  home.file = {
    # Global agent rules for the Zed agent
    ".config/zed/AGENTS.md".source = ./GLOBAL.md;
    # Global agent skills
    ".agents/skills/unattended/SKILL.md".text = unattended.generateSkill;
  };
}
