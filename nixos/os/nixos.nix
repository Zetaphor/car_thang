{ lib, ... }:
let
  vars = {
    doomEnabled = true;
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
        "compress=zstd"
        "noatime"
      ];
    };
  };

  system.stateVersion = "24.11";
}
