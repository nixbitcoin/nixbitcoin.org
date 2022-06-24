{ config, pkgs, lib, ... }:
{
  imports = [
    <nix-bitcoin/modules/presets/secure-node.nix>

    ./base.nix
    ./website
    ./matrix.nix
    ./backup.nix
  ];

  nix-bitcoin.onionServices.bitcoind.public = true;
  services.bitcoind = {
    i2p = true;
    tor.enforce = false;
    tor.proxy = false;
  };

  services.clightning = {
    enable = true;
    plugins.clboss.enable = true;
    extraConfig = ''
      alias=nixbitcoin.org
    '';
  };
  nix-bitcoin.onionServices.clightning.public = true;
  systemd.services.clightning.serviceConfig.TimeoutStartSec = "5m";

  services.rtl.enable = true;
  services.rtl.nodes.clightning = true;

  services.electrs.enable = true;

  services.btcpayserver = {
    enable = true;
    lightningBackend = "clightning";
    lbtc = true;
  };
  nix-bitcoin.onionServices.btcpayserver.enable = true;

  nix-bitcoin.netns-isolation.enable = true;

  services.joinmarket = {
    enable = true;
    yieldgenerator.enable = true;
  };
  services.joinmarket-ob-watcher.enable = true;

  services.mempool = {
    enable = true;
    electrumServer = "fulcrum";
  };
  services.fulcrum = {
    enable = true;
    port = 50011;
    extraConfig = ''
      fast-sync = 2000
    '';
  };

  nix-bitcoin-org.website = {
    enable = true;
    donate.btcpayserverAppId = "3NKhG5wANegkfmXJ5x4ZNuSAB1z5";
  };

  programs.ssh.knownHosts."freak.seedhost.eu".publicKey = "ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBD2TmdE89ZD4XshcIcXZPLFC/nDxZdAr9yrH2/2OCNKEo/Ex60y8TQjp93isjdDj7Grf/GpW60OONfXTFe0r5iM=";

  # TODO-EXTERNAL
  # Remove this when https://github.com/NixOS/nixpkgs/issues/148009 is resolved
  systemd.services.nginx.serviceConfig.SystemCallFilter =
    lib.mkForce "~@cpu-emulation @debug @keyring @ipc @mount @obsolete @privileged @setuid";

  environment.shellAliases = {
    sudo = "doas";
  };

  nix-bitcoin.configVersion = "0.0.70";
}
