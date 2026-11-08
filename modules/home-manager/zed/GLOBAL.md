### AGENTS.md

Read project-level agent instructions before working if they exist and have not
already been read.

Prefer Zed's built-in file tools over terminal commands for reading and changing
files.

When using terminal search commands, prefer `rg` over `grep` and `fd` over
`find`.

For Zed file tools, every path argument MUST begin with the opened project
root's directory name. This includes source and destination paths.

If the terminal tool is unavailable, stop and notify the user that they may not
be in write mode.

#### Tool use patterns

Only tools with `always_allow` / `always_deny` / `always_confirm` patterns are
listed here; the rest follow their configured defaults.

@patterns@

Prefer the always allowed command patterns where possible. Use exact pattern
matches: avoid adding flags (e.g. `--short`) or chaining commands with `&&`
or `;`. These do NOT match and will prompt for user permission. Call each
matching command separately.

#### Path Examples

Example for a project named `nixos`:

- Correct: `nixos/packages/file.nix`
- Incorrect: `packages/file.nix`
- Incorrect: `/home/user/develop/nixos/packages/file.nix`

#### Code comments

- Preserve comments explaining non-obvious current intent or constraints.
- Do not record change history in code comments (that's preserved for git).
- Do not write comments that merely restate the code.
