# INSTANCES: split under ./instances.
args: import ./instances/shared.nix args // import ./instances/machines.nix args
