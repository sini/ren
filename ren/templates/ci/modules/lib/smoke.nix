{ ren, ... }:
{
  lib.test-version = {
    expr = ren.version;
    expected = "0";
  };
}
