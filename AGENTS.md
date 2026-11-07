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

### Find declarations

```sh
# NixOS modules (replace <source> with stable, unstable, or latest)
nix eval --raw '.#debug.sources.<source>' | xargs -I{} rg -n -C 3 'option' '{}/nixos/modules'
# Home Manager modules
nix eval --raw '.#debug.sources.home-manager' | xargs -I{} rg -n -C 3 'option' '{}/modules'
```

Search related names when the exact option path is unknown. `nix search` searches packages, not options.

### Inspect available options and metadata

```sh
# List available options in a namespace
nix eval --json '.#nixosConfigurations.<host>.options.<path>' --apply builtins.attrNames
# Inspect an option's metadata
nix eval --json '.#nixosConfigurations.<host>.options.<path>' --apply 'o: { inherit (o) description declarations; type = o.type.description; }'
```

### Read the effective value

Read/search first; evaluate only when the resulting value is unclear.

```sh
nix eval .#nixosConfigurations.<host>.config.<path>
```
