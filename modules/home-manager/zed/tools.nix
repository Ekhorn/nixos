{ lib }:

let
  gated = {
    terminal = {
      default = "confirm";
      always_allow = [
        { pattern = "^git --no-optional-locks status$"; }
        { pattern = "^git --no-optional-locks --no-pager diff( --cached)?$"; }
      ];
      always_deny = [ ];
      always_confirm = [ ];
    };
    edit_file = {
      default = "allow";
    };
    write_file = {
      default = "allow";
    };
    delete_path = {
      default = "confirm";
    };
    copy_path = {
      default = "confirm";
    };
    move_path = {
      default = "confirm";
    };
    create_directory = {
      default = "confirm";
    };
    fetch = {
      default = "confirm";
    };
    search_web = {
      # Requires Zed Pro, unless an MCP server is configured
      default = "deny";
    };
    skill = {
      default = "confirm";
    };
  };

  ungated = [
    "diagnostics"
    "find_path"
    "list_agents_and_models"
    "list_directory"
    "read_file"
    "grep"
  ];

  byDefault =
    permission: builtins.attrNames (lib.filterAttrs (_: tool: tool.default == permission) gated);

  byDefaultConfirm = byDefault "confirm";
  byDefaultDeny = byDefault "deny";
  byDefaultAllow = byDefault "allow";

  allowed = ungated ++ byDefaultAllow;
  notAllowed = byDefaultConfirm ++ byDefaultDeny;

  withPatterns =
    option: builtins.attrNames (lib.filterAttrs (_: tool: (tool.${option} or [ ]) != [ ]) gated);

  patterns = lib.unique (
    lib.concatLists (
      map withPatterns [
        "always_allow"
        "always_deny"
        "always_confirm"
      ]
    )
  );
in
{
  inherit
    gated
    ungated
    byDefault
    withPatterns
    allowed
    notAllowed
    patterns
    ;

  all = builtins.attrNames gated ++ ungated;
}
