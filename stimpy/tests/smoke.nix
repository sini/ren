{ lib, stimpy }:
{
  test-lib-is-attrset = {
    expr = builtins.isAttrs stimpy;
    expected = true;
  };
  test-control-throws = {
    expr = throw "boom";
    expectedError.type = "ThrownError";
  };
}
