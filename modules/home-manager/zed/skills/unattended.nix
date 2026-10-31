{ lib }:

let
  inherit (import ../tools.nix { inherit lib; }) tools allowed notAllowed;

  sort = builtins.sort (a: b: a < b);

  mkNote =
    name:
    let
      tool = tools.${name} or { };
      patterns = opt: lib.concatMapStringsSep ", " (p: p.pattern or p) (tool.${opt} or [ ]);
      part = opt: verb: lib.optional (tool.${opt} or [ ] != [ ]) "always ${verb}: ${patterns opt}";
      parts =
        lib.optional (tool.default or "" == "deny") "denied by default"
        ++ part "always_allow" "allows"
        ++ part "always_deny" "denies"
        ++ part "always_confirm" "confirms";
    in
    lib.optionalString (parts != [ ]) " (${lib.concatStringsSep "; " parts})";

  mkList = list: lib.concatMapStringsSep "\n" (name: "- ${name}${mkNote name}") (sort list);

  generateSkill = ''
    ---
    name: unattended
    description: Use only tools that run without user approval in write mode (read/analysis tools plus file edits); no terminal, network access, or sub-agent delegation.
    ---

    Use only tools that do not require user permission in write mode.

    Allowed (no user approval required):

    ${mkList allowed}

    Do not use (requires user approval or is denied):

    ${mkList notAllowed}

    Do not use `spawn_agent`, `ask_user`, or `create_thread`: sub-agent delegation,
    asking the user, and spawning new threads do not complete unattended.

    Do not probe whether a disallowed operation will request approval; if an
    operation is unavailable or blocked, continue with the allowed tools where
    possible and report the limitation.
  '';
in
{
  inherit generateSkill;
}
