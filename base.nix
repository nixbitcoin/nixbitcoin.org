# The base system without services

{ config, pkgs, lib, ... }:

with lib;
{
  imports = [ ./hardware.nix ];

  networking.hostName = "nixbitcoin";
  time.timeZone = "UTC";

  services.openssh = {
    enable = true;
    passwordAuthentication = false;
  };
  users.users.root = {
    openssh.authorizedKeys.keys = [
      "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDjOWkBbvyTd5VhlWHecyAbsTFbQyxnXOJw+or9uQG5fbq7DlQFhFbDpD62jUzoNlsmfeLOgudyrD5A++Mk8NQLzGauBvmjql5RmfL1ZScqHPQi01sXQcEqbCRRR7O4tBynpJYktXGs7QJOIPikPBDBP2hBIxKkuHfv2nryiDcOT3DxgWbzEqvCRfHlH/D5NimPFP142gyGALbItCEBjoNKOPEOj/9t4FGEwXlX7bmggVLfIi6GakgxF78V2X1+5RIlQWbvfMrfQWSjKzqdS/vIqp7jZJziK66lqrJo+BQGNorh81Bsgy/p0SMdv8KoN3Xvrdxf/4pyADxmkyr1y5ryGabMHy2xqB3gna6XrrJThhMEbOD1xfwOZ7vKDu8YIfK1wzXnt3cwl+fHMlPicmi/Vh2qkYuBPbVxo1g5+XyCq9roatdvzsVdSX3+a1U1CeGee1q1p8Hf8oY5PrQBhv80RqI3HAbr3tdZD7HlPL9XY9arbm4XP67qrxM+P1L4eBx5N9vCkOjKs0Pp1XHwyfGGiTYFYsZCR6MG8SKZ6Q+zWR4UKTEgY0rNT2//wlnDlkaUl6OYAKJUYtxffZo5WjIpqAzq7qSi+Me0AD/M6QPRZpXjKOrlisagO9uV9/WycV/pVjryJcmlhyDlAwaTQeypyleeryxHNEwBYoVdyMz52Q==" # nixbitcoindev
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOVyeXpwHsOV8RMtQwzPGhOlJ8n5/+4hGa2jc7T47CJC" # nickler
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICW0rZHTE+/gRpbPVw0Q6Wr3csEgU7P+Q8Kw6V2xxDsG" # Erik Arvstedt
    ];
  };

  # Refused connections are happening constantly on a public server and can be ignored
  networking.firewall.logRefusedConnections = false;

  environment.systemPackages = with pkgs; [
    vim
  ];

  system.stateVersion = "20.09";
}
