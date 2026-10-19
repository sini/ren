# CLASSES: homeManager and its sub-class.
{
  ren,
  h,
  ...
}:
let
  inherit (ren.lib) and within;
  inherit (h) pkgsOf;
in
{
  # one class, four homes
  homeManager = [
    {
      at = and [
        ren.kinds.user
        (within ren.kinds.host)
      ];
      into = { user, ... }: ms: { nixos.home-manager.users.${user.name}.imports = ms; };
    }
    {
      at = and [
        ren.kinds.user
        (within ren.kinds.mac)
      ];
      into = { user, ... }: ms: { darwin.home-manager.users.${user.name}.imports = ms; };
    }
    {
      at = and [
        ren.kinds.user
        (within ren.kinds.phone)
      ];
      into = { ... }: ms: { droid.home-manager.config.imports = ms; };
    }
    {
      # standalone
      at = and [
        ren.kinds.user
        (within ren.kinds.home)
      ];
      into =
        { home, ... }:
        ms: {
          homeConfigurations.${home.name} = home.channel.home-manager.lib.homeManagerConfiguration {
            pkgs = pkgsOf home;
            modules = ms;
          };
        };
    }
  ];

  # a sub-class, forwarded in place
  homeDarwin = {
    at = and [
      ren.kinds.user
      (within ren.kinds.mac)
    ];
    into = { ... }: ms: { homeManager.imports = ms; };
  };

}
