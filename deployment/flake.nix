{
  inputs.nix-bitcoin.url = "github:fort-nix/nix-bitcoin/release";
  inputs.nixpkgs.follows = "nix-bitcoin/nixpkgs";
  inputs.flake-utils.follows = "nix-bitcoin/flake-utils";

  # The installer system requires NixOS 22.05 for automatic initrd-secrets support
  # https://github.com/NixOS/nixpkgs/pull/176796
  inputs.nixpkgs-kexec.url = "github:erikarvstedt/nixpkgs/improve-netboot-initrd";

  outputs = { self, nixpkgs, nixpkgs-kexec, flake-utils, ... }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
      in {
        packages = rec {

          installerSystemVM = (import "${nixpkgs}/nixos" {
            inherit system;
            configuration = {
              imports = [ ./1-installer-system.nix ];
              virtualisation.graphics = false;
              environment.etc.base-system.source = baseSystem;
            };
          }).vm;

          installerSystemKexec = (nixpkgs-kexec.lib.nixosSystem {
            inherit system;
            modules = [
              ({ modulesPath, ... }: {
                imports = [
                  ./1-installer-system.nix
                  "${modulesPath}/installer/kexec/kexec-boot.nix"
                ];
                services.openssh.hostKeys = [
                  {
                    path = "/run/keys/ssh-host-key";
                    type = "ed25519";
                  }
                ];
                boot.kernelParams = [
                  # Allows certain forms of remote access, if the hardware is setup right
                  "console=ttyS0,115200"
                  # Reboot the machine upon fatal boot issues
                  "panic=30"
                  "boot.panic_on_fail"
                ];
              })
            ];
          }).config.system.build.kexecBoot;

          baseSystem = (nixpkgs.lib.nixosSystem {
            inherit system;
            modules = [ ../base.nix ];
          }).config.system.build.toplevel;
        };
      });
}
