{ lib }:

let
  inherit (import ./tools.nix { inherit lib; }) gated;

  # Sort a list of strings alphabetically.
  sort = builtins.sort (a: b: a < b);

  mkNote =
    name:
    let
      tool = gated.${name} or { };
      patterns = opt: lib.concatMapStringsSep ", " (p: p.pattern or p) (tool.${opt} or [ ]);
      part = opt: verb: lib.optional (tool.${opt} or [ ] != [ ]) "always ${verb}: ${patterns opt}";
      parts =
        lib.optional (tool.default or "" == "deny") "denied by default"
        ++ part "always_allow" "allows"
        ++ part "always_deny" "denies"
        ++ part "always_confirm" "confirms";
    in
    lib.optionalString (parts != [ ]) " (${lib.concatStringsSep "; " parts})";

  # Render a bullet list of tool names with their mkNote annotations.
  mkList = list: lib.concatMapStringsSep "\n" (name: "- ${name}${mkNote name}") (sort list);
in
{
  inherit sort mkNote mkList;
}
