---
name: nix
description: Use when working with Nix modules and options to find option declarations, inspect available options and metadata, and read effective values in this NixOS configuration.
---

Find declarations, inspect available options and metadata, and read effective
values in this NixOS configuration.

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
