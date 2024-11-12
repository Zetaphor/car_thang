{
  nixpkgs,
  config,
  lib,
  pkgs,
  ...
}:
{
  imports = [
    ../shared/sys.nix
    "${nixpkgs}/nixos/modules/profiles/minimal.nix"
    "${nixpkgs}/nixos/modules/profiles/headless.nix"
    "${nixpkgs}/nixos/modules/profiles/perlless.nix"
  ];

  disabledModules = [
    "${nixpkgs}/nixos/modules/profiles/all-hardware.nix"
    "${nixpkgs}/nixos/modules/profiles/base.nix"
    "${nixpkgs}/nixos/modules/profiles/installation-device.nix"
  ];

  i18n.supportedLocales = [ (config.i18n.defaultLocale + "/UTF-8") ];

  nix.enable = false;
  nix.settings.experimental-features = "nix-command flakes";

  fileSystems."/" = {
    device = "tmpfs";
    fsType = "tmpfs";
    options = [ "mode=0755" ];
  };

  services.udev.enable = false;
  services.lvm.enable = false;
  security.sudo.enable = false;

  networking = {
    hostName = "superbird";
    interfaces.usb0 = {
      name = "usb0";
      useDHCP = false;
      ipv4.addresses = [
        {
          address = "172.16.42.2";
          prefixLength = 24;
        }
      ];
    };
    defaultGateway = {
      address = "172.16.42.1";
      interface = "usb0";
    };
    nameservers = [
      "1.1.1.1"
      "8.8.8.8"
    ];
  };

  boot = {
    initrd = {
      compressor = "cat";

      systemd = {
        enable = true;
        emergencyAccess = true;
        network.enable = true;

        services."systemd-networkd".environment.SYSTEMD_LOG_LEVEL = "debug";

        initrdBin = with pkgs; [
          parted
          dosfstools
          btrfs-progs
          iproute2
          iputils
          vim
        ];

        users.root.shell = "/bin/bash";

        contents = {
          "/superbird/init".source = ./initrd.sh;
          "/superbird/ampart-v1.4-aarch64-static".source = ../resources/ampart-v1.4-aarch64-static;
          "/superbird/decrypted.dtb".source = ../resources/stock_dtb.img;
          "/superbird/bootloader.img".source = ../resources/bootloader.img;
          "/superbird/Image".source = "${config.system.build.kernel}/Image";
          "/superbird/superbird.dtb".source = ../resources/meson-g12a-superbird.dtb;
          "/superbird/bootargs.txt".source = ../resources/env_p2.txt;

          "/etc/ssh/ssh_host_ed25519_key".source = ../resources/ssh/ssh_host_ed25519_key;
          "/etc/ssh/ssh_host_rsa_key".source = ../resources/ssh/ssh_host_rsa_key;
        };
      };

      network = {
        enable = true;
        ssh = {
          enable = true;
          port = 22;
          hostKeys = [
            ../resources/ssh/ssh_host_rsa_key
            ../resources/ssh/ssh_host_ed25519_key
          ];
          authorizedKeys = [ "ssh-rsa nokeysneeded" ];
        };
      };

      supportedFilesystems = lib.mkForce [
        "vfat"
        "btrfs"
      ];
      availableKernelModules = lib.mkForce [
        "loop"
        "overlay"
      ];
      kernelModules = lib.mkForce [ ];
    };
  };

  hardware.enableRedistributableFirmware = false;
  hardware.firmware = [ ];
  environment.systemPackages = lib.mkForce [ ];

  documentation.enable = lib.mkForce false;
  documentation.nixos.enable = lib.mkForce false;

  services.udisks2.enable = false;
  system.extraDependencies = lib.mkForce [ ];

  system.stateVersion = "24.11";
}
