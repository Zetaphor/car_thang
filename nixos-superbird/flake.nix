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
    }@inputs:
    let
      inherit (self) outputs;
      inherit (nixpkgs.lib) nixosSystem;
    in
    {
      nixosConfigurations = {
        superbird = nixosSystem {
          system = "aarch64-linux";
          specialArgs = inputs;
          modules = [
            ./nixos/superbird.nix
            (
              { config, pkgs, ... }:
              let
                overlay-unstable = final: prev: {
                  cage = prev.cage.overrideAttrs (old: {
                    patches = [
                      (pkgs.fetchpatch {
                        url = "https://patch-diff.githubusercontent.com/raw/cage-kiosk/cage/pull/365.patch";
                        hash = "sha256-Grap5a3+8JkxMGS2dFLcKrElDvjq9QKaLQqhL722keo=";
                      })
                    ];
                  });
                };
              in
              {
                nixpkgs.overlays = [ overlay-unstable ];
              }
            )
            (
              { pkgs, config, ... }:
              {
                system.build.ext4 = pkgs.callPackage "${nixpkgs}/nixos/lib/make-ext4-fs.nix" {
                  volumeLabel = "NIXOS";
                  storePaths = [ config.system.build.toplevel ];
                  populateImageCommands = ''
                    mkdir -p ./files/bin
                    cp ${config.system.build.toplevel}/init ./files/bin/init
                  '';
                };
              }
            )
            agenix.nixosModules.default
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
