{ pkgs, ... }:

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
    package = pkgs.latest.zed-editor;
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
            available_models = [
              {
                name = "Qwen3.8-27B";
                max_tokens = 262144;
                max_output_tokens = 131072;
                max_completion_tokens = 131072;
                reasoning_effort = "medium";
              }
            ];
          };
        };
      };

      agent = {
        enable_feedback = false;
        show_turn_stats = true;
        default_model = {
          provider = "gufo";
          model = "Qwen3.8-27B";
        };
        favorite_models = [ ];
        sandbox_permissions = {
          allow_unsandboxed = true;
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

  # Global agent rules for the Zed agent
  home.file."AGENTS.md" = {
    target = ".config/zed/AGENTS.md";
    source = ./GLOBAL.md;
  };

  # Global agent skills
  home.file."~/.agents/skills/unattended/SKILL.md" = {
    target = ".agents/skills/unattended/SKILL.md";
    source = ./skills/unattended.md;
  };
}
