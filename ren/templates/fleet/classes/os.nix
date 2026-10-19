# CLASSES: darwin and the os alias.
{
  ren,
  ...
}:
{
  darwin = {
    at = ren.kinds.mac;
    into =
      { mac, ... }:
      ms: {
        darwinConfigurations.${mac.name} = mac.channel.darwin.lib.darwinSystem {
          system = mac.system.name;
          modules = ms;
        };
      };
  };
  # one key, either OS
  os = [
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
