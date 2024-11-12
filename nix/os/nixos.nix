{ lib, ... }:
let
  vars = {
    guiEnabled = true;
    doomEnabled = false;
    cogEnabled = true;
    firefoxEnabled = false;
    chromiumEnabled = false;
  };
in
{
  imports = [
    ../shared/options.nix
    { inherit vars; }
    ../shared/sys.nix
    ./profile.nix
    ./connectivity.nix
    ./user.nix
    ./env.nix
    ./fun.nix
    ./gui.nix
  ];

  fileSystems = {
    "/" = lib.mkForce {
      device = "/dev/mmcblk2p2";
      fsType = "btrfs";
      options = [
        "subvol=root"
        "compress=zstd"
        "noatime"
      ];
    };
    "/var/log" = {
      device = "/dev/mmcblk2p2";
      fsType = "btrfs";
      options = [
        "subvol=log"
        "compress=zstd"
        "noatime"
      ];
    };
    "/swap" = {
      device = "/dev/mmcblk2p2";
      fsType = "btrfs";
      options = [
        "subvol=swap"
        "noatime"
      ];
    };
  };

  swapDevices = [
    {
      device = "/swap/swapfile";
      size = 512;
    }
  ];

  system.stateVersion = "24.11";
}
