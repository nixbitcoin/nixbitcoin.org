let
  # FIXME:
  target = "root@nixbitcoin.org";

  extraSources = {
    "hardware-configuration.nix".file = toString ../hardware-configuration.nix;
    website.file = {
      path = toString ../website;
    };
    "matrix.nix".file = toString ../matrix.nix;
    "mail.nix".file = toString ../mail.nix;
  };

  krops = (import <nix-bitcoin> {}).krops;
in
krops.pkgs.krops.writeDeploy "deploy" {
  inherit target;

  source = import ./sources.nix { inherit extraSources krops; };

  # Avoid having to create a sentinel file.
  # Otherwise /var/src/.populate must be created on the target node to signal krops
  # that it is allowed to deploy.
  force = true;
}
