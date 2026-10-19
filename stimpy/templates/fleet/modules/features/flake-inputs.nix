# Flake inputs: any scope declares the inputs it needs; the fleet writes them for flake-file.
{ ren, ... }:
{
  ren.channels.flake-inputs = {
    fold = ren.lib.fold.attrs;
    to = _: ren.fleet.main; # no `at`: any scope emits
    into = { ... }: inputs': { flake-file.inputs = inputs'; };
  };
}
