# Storage deployment is defined in ./deployment/2-format-storage.sh

{ config, lib, pkgs, modulesPath, ... }:

let
  # When a device marked with `nonessentialDevice` is unavailable,
  # booting succeeds and systemd marks the system as degraded.
  # This allows the system to run when one device fails.
  nonessentialDevice = [
    "nofail"
    "x-systemd.device-timeout=10s"
  ];

  hetznerDedicated = {
    boot.initrd.availableKernelModules = [ "xhci_pci" "ahci" "sd_mod" ];
    boot.kernelModules = [ "kvm-amd" ];
    powerManagement.cpuFreqGovernor = "powersave";
    hardware.cpu.amd.updateMicrocode = true;
  };

  hetznerCloud = {
    boot.initrd.availableKernelModules = [ "ata_piix" "virtio_pci" "virtio_scsi" "xhci_pci" "sd_mod" "sr_mod" ];
  };

  bindMount = srcPath: {
    device = srcPath;
    options = [ "bind" ];
    # Silence warning:
    # systemd-fstab-generator: Checking was requested for "<srcPath>", but it is not a device.
    noCheck = true;
  };
in
{
  imports = [
    hetznerDedicated
    # hetznerCloud
  ];

  fileSystems."/" = {
    device = "rpool/root";
    fsType = "zfs";
  };

  # TODO-EXTERNAL:
  # Remove the ZFS filesystem definitions when
  # https://github.com/NixOS/nixpkgs/issues/62644 has been implemented
  fileSystems."/nix" = {
    device = "rpool/nix";
    fsType = "zfs";
    # Required to make this mount compatible with ZFS's auto-mount mechanism
    # for datasets with a non-legacy `mountpoint`.
    options = [ "zfsutil" ];
  };

  fileSystems."/var/lib/db" = {
    device = "rpool/root/db";
    fsType = "zfs";
    options = [ "zfsutil" ];
  };

  fileSystems."/boot1" = {
    device = "/dev/disk/by-label/boot1";
    fsType = "vfat";
    options = nonessentialDevice;
  };

  fileSystems."/boot2" = {
    device = "/dev/disk/by-label/boot2";
    fsType = "vfat";
    options = nonessentialDevice;
  };

  swapDevices = [
    { device = "/dev/disk/by-label/swap1"; options = nonessentialDevice; }
    { device = "/dev/disk/by-label/swap2"; options = nonessentialDevice; }
  ];

  boot.supportedFilesystems = [ "zfs" ];

  boot.loader.grub = {
    enable = true;
    mirroredBoots = [
      { path = "/boot1"; devices = [ "/dev/sda" ]; }
      { path = "/boot2"; devices = [ "/dev/sdb" ]; }
    ];
  };

  # Use special database dataset
  fileSystems."/var/lib/postgresql" = bindMount "/var/lib/db/postgresql";
  fileSystems."/var/lib/mysql" = bindMount "/var/lib/db/mysql";
}
