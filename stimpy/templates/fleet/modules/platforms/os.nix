# os: one class key that lands on either OS.
{ ren, ... }:
{
  ren.classes.os = [
    # one key, either OS
    {
      at = ren.kinds.host;
      into = { ... }: ms: { nixos.imports = ms; };
    }
    {
      at = ren.kinds.mac;
      into = { ... }: ms: { darwin.imports = ms; };
    }
  ];
}
