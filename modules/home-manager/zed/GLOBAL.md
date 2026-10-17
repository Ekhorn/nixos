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

#### Path Examples

Example for a project named `nixos`:

- Correct: `nixos/packages/file.nix`
- Incorrect: `packages/file.nix`
- Incorrect: `/home/user/develop/nixos/packages/file.nix`
