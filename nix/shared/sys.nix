{
  pkgs,
  config,
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
  system.activationScripts.installInitScript = ''
    ln -fs $systemConfig/init /bin/init
  '';

  boot = {
    kernelPackages = pkgs.recurseIntoAttrs (pkgs.linuxPackagesFor superbird_kernel);
    kernelModules = [
      "btrfs"
      "af_alg"
      "ipv6"
      "g_ether"
    ];

    loader.grub.enable = false;

    initrd.includeDefaultModules = false;
    initrd.supportedFilesystems = [ "btrfs" ];
    initrd.kernelModules = [
      "g_ether"
      "btrfs"
    ];
    supportedFilesystems = [
      "vfat"
      "btrfs"
    ];

    postBootCommands = ''
      set -x
      # On the first boot do some maintenance tasks
      if [ -f /nix-path-registration ]; then
        # Ensure that / and a few others are owned by root https://github.com/NixOS/nixpkgs/pull/320643
        chown -f 0:0 /
        chown -f 0:0 /nix
        chown -f 0:0 /bin

        # expand filesystem
        rootPath=/
        ${pkgs.btrfs-progs}/bin/btrfs filesystem resize max $rootPath

        # Register the contents of the initial Nix store
        ${config.nix.package.out}/bin/nix-store --load-db < /nix-path-registration

        # nixos-rebuild also requires a "system" profile and an /etc/NIXOS tag.
        touch /etc/NIXOS
        # ${config.nix.package.out}/bin/nix-env -p /nix/var/nix/profiles/system --set /run/current-system

        # Prevents this from running on later boots.
        rm -f /nix-path-registration
      fi
    '';
  };
}
