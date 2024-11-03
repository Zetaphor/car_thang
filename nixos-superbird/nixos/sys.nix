{
  pkgs,
  config,
  lib,
  ...
}:
let
  superbird_kernel =
    (pkgs.linuxManualConfig {
      version = "6.6.43";
      modDirVersion = "6.6.43";
      # extraMeta.branch = "6.6.43";

      configfile = ../resources/superbird_defconfig;
      allowImportFromDerivation = true;

      src = pkgs.fetchFromGitHub {
        owner = "alexcaoys";
        repo = "linux-superbird-6.6.y";
        rev = "95c292d859f44efaffcea509fc2575d028d81458";
        sha256 = "sha256-Or1bWEJbckQ9u8GWLakNdRe1Vi3OXyR1WPB17I1F6lQ=";
      };

      kernelPatches = [ ];
    }).overrideAttrs
      (old: {
        nativeBuildInputs = old.nativeBuildInputs ++ [ pkgs.ubootTools ];
        buildDTBs = false;
      });
in
{
  fileSystems = {
    "/" = lib.mkForce {
      device = "/dev/mmcblk2p2";
      fsType = "ext4";
    };
  };

  system.activationScripts.installInitScript = ''
    ln -fs $systemConfig/init /bin/init
  '';

  boot = {
    kernelPackages = pkgs.recurseIntoAttrs (pkgs.linuxPackagesFor superbird_kernel);
    kernelModules = [
      "ext4"
      "af_alg"
      "ipv6"
      "g_ether"
    ];

    loader.grub.enable = false;

    initrd.includeDefaultModules = false;
    initrd.kernelModules = [ "ext4" ];

    postBootCommands =
      ''
        if [ -f /nix-path-registration ]; then
          ${config.nix.package.out}/bin/nix-store --load-db < /nix-path-registration && rm /nix-path-registration
        fi
      ''
      + ''
        ${config.nix.package.out}/bin/nix-env -p /nix/var/nix/profiles/system --set /run/current-system
      '';
  };
}
