# Option shorthands shared by every kind file (module args).
{ lib, ... }:
let
  opt = type: default: lib.mkOption { inherit type default; };
  maybe = type: opt (lib.types.nullOr type) null;
in
{
  _module.args = { inherit opt maybe; };
}
