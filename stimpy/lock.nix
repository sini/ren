let
  lock = builtins.fromJSON (builtins.readFile ./flake.lock);
  node = lock.nodes.${lock.nodes.${lock.root}.inputs.nixpkgs}.locked;
in
{
  nixpkgs = builtins.fetchTarball {
    url = "https://github.com/${node.owner}/${node.repo}/archive/${node.rev}.tar.gz";
    sha256 = node.narHash;
  };
}
