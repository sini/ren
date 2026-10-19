{
  gen ? import (builtins.fetchTarball {
    url = "https://github.com/sini/gen/archive/bcbc5ca579614643fa3433034fd0248b0d551f65.tar.gz";
    sha256 = "1hlrc843zvzk6w59x32k9c7g7hl4gvw2wcjp6sg03gx0204gskrz";
  }) { },
}:
import ./nix/lib { inherit gen; }
