# Stub inputs for templates/fleet: every system builder is a bare `lib.evalModules`
# over freeform options, so fleet content evaluates without nixpkgs modules.
{ lib }:
let
  t = lib.types;
  freeform = {
    freeformType = t.lazyAttrsOf t.anything;
  };
  stubOptions = {
    imports = [ freeform ];
    options = {
      home-manager.users = lib.mkOption {
        type = t.attrsOf (t.submoduleWith { modules = [ freeform ]; });
        default = { };
      };
      microvm.vms = lib.mkOption {
        type = t.attrsOf (
          t.submodule {
            options.pkgs = lib.mkOption { type = t.anything; };
            options.config = lib.mkOption { type = t.deferredModule; };
          }
        );
        default = { };
      };
      age.secrets = lib.mkOption {
        type = t.attrsOf t.anything;
        default = { };
      };
    };
  };
  eval =
    pkgs: ms:
    lib.evalModules {
      modules = ms ++ [
        stubOptions
        { _module.args.pkgs = pkgs; }
      ];
    };
  # `channel` tags each pkgs set so tests can tell stable from edge
  pkgsOn = channel: s: {
    inherit channel;
    hello = "hello-${s}";
    helix = "helix-${s}";
    linuxPackages = "linuxPackages-${s}";
    linuxPackages_latest = "linuxPackages_latest-${s}";
  };
  nixpkgsOf =
    channel:
    let
      legacyPackages = lib.genAttrs [
        "x86_64-linux"
        "aarch64-linux"
        "aarch64-darwin"
      ] (pkgsOn channel);
    in
    {
      inherit legacyPackages;
      lib = lib // {
        nixosSystem = { system, modules }: { inherit (eval legacyPackages.${system} modules) config; };
      };
    };
  nixpkgs = nixpkgsOf "stable";
  inherit (nixpkgs) legacyPackages;
  home-manager = {
    lib.homeManagerConfiguration = { pkgs, modules }: { inherit (eval pkgs modules) config; };
    nixosModules.home-manager = { };
    darwinModules.home-manager = { };
  };
in
{
  inherit nixpkgs home-manager;
  stubEval = eval; # exposes the stub builder so tests can evaluate a guest deferredModule
  nixpkgs-unstable = nixpkgsOf "edge";
  home-manager-unstable = home-manager;
  nix-darwin.lib.darwinSystem = { system, modules }: {
    inherit (eval legacyPackages.${system} modules) config;
  };
  nix-on-droid.lib.nixOnDroidConfiguration = { pkgs, modules }: {
    inherit (eval pkgs modules) config;
  };
  terranix.lib.terranixConfiguration = { system, modules }: {
    inherit (eval legacyPackages.${system} modules) config;
  };
  colmena.lib.makeHive = hive: hive;
  agenix.nixosModules.default = { };
  microvm.nixosModules = {
    microvm = { };
    host = { };
  };
  impermanence.nixosModules.impermanence = { };
}
