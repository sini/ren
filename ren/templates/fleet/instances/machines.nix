# INSTANCES: machines and people.
{
  ren,
  ...
}:
{
  host = {
    lb = {
      environment = ren.environment.prod;
      channel = ren.channel.stable;
      system = ren.system.x86_64-linux;
      addr = "10.0.1.1";
    };
    web-1 = {
      environment = ren.environment.prod;
      channel = ren.channel.stable;
      system = ren.system.x86_64-linux;
      addr = "10.0.1.10";
      settings.kernel.channel = "latest";
    };
    web-2 = {
      environment = ren.environment.prod;
      channel = ren.channel.stable;
      system = ren.system.x86_64-linux;
      addr = "10.0.1.11";
    };
    stage = {
      environment = ren.environment.staging;
      channel = ren.channel.edge;
      system = ren.system.x86_64-linux;
      addr = "10.0.2.10";
    };
  };
  guest.ci = {
    environment = ren.environment.staging;
    channel = ren.channel.stable;
    system = ren.system.x86_64-linux;
    addr = "10.0.2.20";
    on = ren.host.stage;
  };
  mac.studio = {
    environment = ren.environment.staging;
    channel = ren.channel.stable;
    system = ren.system.aarch64-darwin;
    addr = "10.0.2.30";
  };
  phone.pixel = {
    environment = ren.environment.staging;
    channel = ren.channel.stable;
    system = ren.system.aarch64-linux;
  };
  home.alice-laptop = {
    user = ren.user.alice;
    channel = ren.channel.edge;
    system = ren.system.x86_64-linux;
  };
  user = {
    alice = {
      groups = [ ren.group.ops ];
      phone = true;
    }; # admin through the closure
    bob.groups = [ ren.group.deploy ];
  };
  db.primary.zone = "eu";
  region.eu.zone = "eu";
  replica.r1 = {
    db = ren.db.primary;
    region = ren.region.eu;
  };
}
