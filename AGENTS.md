# AGENTS.md

## Structure

```
.
├── hosts/                 # Host-specific configurations
│   └── anywhere/          # Minimal remotely deployed server hosts
├── lib/                   # Reusable Nix functions
├── modules/
│   ├── home-manager/      # Reusable Home Manager modules
│   │   └── anywhere/      # Minimal modules for anywhere hosts
│   ├── nixos/             # Reusable NixOS modules
│   │   ├── anywhere/      # Minimal modules for anywhere hosts
│   │   └── remote/        # Remote management modules
│   └── shared/            # Definitions shared across module systems
├── overlays/              # nixpkgs overlays
├── packages/              # Custom packages and derivations
├── patches/               # Upstream patches
└── shells/                # Development shells
```

Anywhere hosts are minimal servers, initially provisioned with `nixos-anywhere`
and maintained with remote builds. They should import only what they need.

### Configuration rules

- Do not create general modules or directories such as `programs`, `services`,
or `security`. Only `common` is allowed.
- Usernames come from the `user` module (`modules/nixos/user.nix`): use
`config.user.username` (e.g. `path:/home/${config.user.username}/...`) instead
of hardcoding a username.
- For modules under `home-manager.users`, pass arguments via `home-manager.extraSpecialArgs`.
- Do not bump `home.stateVersion` or `system.stateVersion` merely to match the pinned release.

### Nix lookups

Nix-specific rules for finding option declarations, inspecting available
options and metadata, and reading effective values live in the `nix` skill.

Use the `skill` tool with the name `nix` for these lookups.
