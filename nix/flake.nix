{
  description = "Spotify CarThing";

  nixConfig = {
    extra-substituters = [
      "https://cache.nixos.org"
      "https://nix-community.cachix.org"
    ];
    extra-trusted-public-keys = [
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
    ];
  };

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    nixpkgsStable.url = "github:NixOS/nixpkgs/nixos-24.05";
    deploy-rs.url = "github:serokell/deploy-rs";

    agenix = {
      url = "github:ryantm/agenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      deploy-rs,
      agenix,
      nixpkgsStable,
    }@inputs:
    let
      overlay-unstable = self: super: {
        # patched version of cage that fixes window centering
        cage = super.cage.overrideAttrs (old: {
          patches = [
            (super.fetchpatch {
              url = "https://patch-diff.githubusercontent.com/raw/cage-kiosk/cage/pull/365.patch";
              hash = "sha256-Grap5a3+8JkxMGS2dFLcKrElDvjq9QKaLQqhL722keo=";
            })
          ];
        });
      };

      overlay-stable = final: prev: {
        stable = import nixpkgsStable {
          system = "aarch64-linux";
        };
      };

      linuxQemu =
        pkgs:
        pkgs.lib.recursiveUpdate pkgs {
          linuxQemu = pkgs.linuxKernel.kernels.linux_6_6.override {
            structuredExtraConfig = with nixpkgs.lib.kernel; {
              BTRFS_FS = yes;
              NLS = yes;
              NLS_DEFAULT = nixpkgs.lib.mkForce (freeform "iso8859-1");
              NLS_CODEPAGE_437 = nixpkgs.lib.mkForce yes;
              FAT_FS = yes;
              VFAT_FS = yes;
              FAT_DEFAULT_CODEPAGE = freeform "437";
              FAT_DEFAULT_IOCHARSET = freeform "ascii";
            };
          };
        };

      inherit (nixpkgs.lib) nixosSystem;
    in
    {
      nixosConfigurations = {
        superbird = nixosSystem {
          system = "aarch64-linux";
          specialArgs = inputs;
          modules = [
            ({
              nixpkgs.overlays = [
                overlay-unstable
                overlay-stable
              ];
            })
            ./os/nixos.nix
            (
              {
                lib,
                pkgs,
                config,
                ...
              }:
              {
                system.build.btrfs = pkgs.callPackage ./shared/make-btrfs-fs.nix {
                  volumeLabel = "root";
                  storePaths = config.system.build.toplevel;
                  btrfs-progs = pkgs.btrfs-progs.overrideAttrs (oldAttrs: {
                    src = pkgs.fetchFromGitHub {
                      owner = "kdave";
                      repo = "btrfs-progs";
                      # devel 2024.09.10; Remove v6.11 release.
                      rev = "c75b2f2c77c9fdace08a57fe4515b45a4616fa21";
                      hash = "sha256-PgispmDnulTDeNnuEDdFO8FGWlGx/e4cP8MQMd9opFw=";
                    };

                    patches = [
                      ./shared/mkfs-btrfs-force-root-ownership.patch
                    ];
                    postPatch = "";

                    nativeBuildInputs = oldAttrs.nativeBuildInputs ++ [
                      pkgs.autoconf
                      pkgs.automake
                    ];
                    preConfigure = "./autogen.sh";

                    version = "6.11.0.pre";
                  });
                  populateImageCommands = ''
                    mkdir -p ./files/bin
                    cp ${config.system.build.toplevel}/init ./files/bin/init
                  '';
                  subvolMap =
                    let
                      fileSystems = builtins.filter (
                        fs: (builtins.any (opt: lib.hasPrefix "subvol=" opt) fs.options)
                      ) config.system.build.fileSystems;
                      stripSubVolOption = opt: lib.removePrefix "subvol=" opt;
                      getSubVolOption =
                        opts: stripSubVolOption (builtins.head (builtins.filter (opt: lib.hasPrefix "subvol=" opt) opts));
                      subvolMap = builtins.listToAttrs (
                        builtins.map (fs: {
                          name = "${fs.mountPoint}";
                          value = "${getSubVolOption fs.options}";
                        }) fileSystems
                      );
                    in
                    subvolMap;
                };
              }
            )
            # agenix.nixosModules.default
          ];
        };

        initrd = nixosSystem {
          system = "aarch64-linux";
          specialArgs = inputs;
          modules = [
            ./initrd/initrd.nix
            (
              {
                lib,
                pkgs,
                config,
                ...
              }:
              {
                boot.postBootCommands = lib.mkForce '''';

                system.build.initfs =
                  let
                    modules = [
                      "loop"
                      "overlay"
                      "g_ether"
                      "nls_cp437"
                      "nls_iso8859_1"
                      "vfat"
                      "btrfs"
                    ];
                    modulesClosure = pkgs.makeModulesClosure {
                      rootModules = modules;
                      kernel = config.system.modulesTree;
                      firmware = config.hardware.firmware;
                      allowMissing = false;
                    };
                  in
                  pkgs.makeInitrd {
                    compressor = "gzip";
                    makeUInitrd = true;

                    prepend = [ "${config.system.build.initialRamdisk}/initrd" ];

                    contents = [
                      {
                        object = modulesClosure;
                        symlink = "/lib";
                      }
                    ];
                  };
              }
            )
          ];
        };

        qemu = nixosSystem {
          system = "aarch64-linux";
          specialArgs = inputs;
          modules = [
            ({
              nixpkgs.overlays = [
                overlay-unstable
                overlay-stable
              ];
            })
            ./os/nixos.nix
            (
              {
                lib,
                pkgs,
                config,
                ...
              }:
              {
                nixpkgs.config.packageOverrides = linuxQemu;

                boot.kernelPackages = lib.mkForce (pkgs.recurseIntoAttrs (pkgs.linuxPackagesFor pkgs.linuxQemu));
                hardware.enableRedistributableFirmware = lib.mkForce true;
                networking.interfaces = lib.mkForce { };

                system.build.btrfs = pkgs.callPackage ./shared/make-btrfs-fs.nix {
                  volumeLabel = "root";
                  storePaths = config.system.build.toplevel;
                  populateImageCommands = ''
                    mkdir -p ./files/bin
                    cp ${config.system.build.toplevel}/init ./files/bin/init
                  '';
                  subvolMap =
                    let
                      fileSystems = builtins.filter (
                        fs: (builtins.any (opt: lib.hasPrefix "subvol=" opt) fs.options)
                      ) config.system.build.fileSystems;
                      stripSubVolOption = opt: lib.removePrefix "subvol=" opt;
                      getSubVolOption =
                        opts: stripSubVolOption (builtins.head (builtins.filter (opt: lib.hasPrefix "subvol=" opt) opts));
                      subvolMap = builtins.listToAttrs (
                        builtins.map (fs: {
                          name = "${fs.mountPoint}";
                          value = "${getSubVolOption fs.options}";
                        }) fileSystems
                      );
                    in
                    subvolMap;
                };
              }
            )
            agenix.nixosModules.default
          ];
        };

        qemu-initrd = nixosSystem {
          system = "aarch64-linux";
          specialArgs = inputs;
          modules = [
            ./initrd/initrd.nix
            (
              {
                config,
                lib,
                pkgs,
                ...
              }:
              {
                boot.postBootCommands = lib.mkForce '''';
                nixpkgs.config.packageOverrides = linuxQemu;

                boot.kernelPackages = lib.mkForce (pkgs.recurseIntoAttrs (pkgs.linuxPackagesFor pkgs.linuxQemu));
                hardware.enableRedistributableFirmware = lib.mkForce true;
                networking.interfaces = lib.mkForce { };

                system.build.initfs =
                  let
                    init = pkgs.writeScript "init" ''
                      #!/bin/bash
                      export PATH=/bin

                      echo ""
                      echo "<<< Something Went Badly >>>"
                      echo ""

                      exec /init
                    '';

                  in
                  pkgs.makeInitrd {
                    compressor = "gzip";
                    makeUInitrd = true;

                    prepend = [ "${config.system.build.initialRamdisk}/initrd" ];

                    contents = [
                      {
                        object = init;
                        symlink = "/root/init";
                      }
                    ];
                  };

                system.stateVersion = "24.11";
              }
            )
          ];
        };
      };

      deploy.nodes = {
        superbird = {
          hostname = "172.16.42.2";
          fastConnection = false;
          remoteBuild = false;
          profiles.system = {
            sshUser = "root";
            path = deploy-rs.lib.aarch64-linux.activate.nixos self.nixosConfigurations.superbird;
            user = "root";
          };
        };
      };
    };
}
