# Ren & Stimpy

![ren](ren-and-stimpy.gif)

Ren's [design](vic/fleet.md) is inspired by [Den](https://github.com/denful/den), a lib for aspect-oriented and context-driven Nix configurations.

[Ren](./ren) is a library built solely on [gen](https://github.com/sini/gen)
(`github:sini/gen`).

[Stimpy](./stimpy) is Ren's sibling, implementing the same Ren specification solely on `nixpkgs.lib`
to provide us a way to compare performance between it and Gen.

[Ren language and semantics](./vic/fleet.md) knows nothing about hosts, users or NixOS. You declare your own
domain, and Ren wires it together.

## Nouns

- **kinds**: the types of things in your domain. They nest with `below` and `spawns`.
- **instances**: the named things of a kind, as `ren.<kind>.<name>`.
- **classes**: module systems that receive configuration, with `at` and `into`.
- **channels**: data that flows from emitter scopes to receivers, with a fold.
- **aspects**: units of configuration. `at` activates them in matching scopes.

## Predicates and folds

Predicates select scopes: `and anyOf not when within has is same`.

Channels merge values with one of these folds: `list set attrs one`.

## Usage

A fleet file takes `ren`, `inputs` and `lib`, and calls `mkFlake`:

```nix
{ ren, inputs, lib }:
ren.lib.mkFlake inputs {
  ren = { ... };
}
```

The flake loads that file:

```nix
outputs = inputs: inputs.ren.lib.load { inherit (inputs.nixpkgs) lib; } inputs (import ./fleet.nix);
```

The fleet template is the reference example. Start from it:

```
nix flake init -t github:vic/ren#fleet
```

See `templates/fleet/flake.nix` and `templates/fleet/fleet.nix`.

## Testing

```
just test
```

This runs nix-unit. Library tests live in `templates/ci/modules/lib`.
Fleet tests live in `templates/ci/modules/fleet`.
