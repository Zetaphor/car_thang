{ nixpkgs, config, ... }:
{
  imports = [
    # "${nixpkgs}/nixos/modules/profiles/headless.nix"
    "${nixpkgs}/nixos/modules/profiles/minimal.nix"
  ];

  disabledModules = [
    "${nixpkgs}/nixos/modules/profiles/all-hardware.nix"
    "${nixpkgs}/nixos/modules/profiles/base.nix"
  ];

  i18n.supportedLocales = [ (config.i18n.defaultLocale + "/UTF-8") ];

  systemd.oomd.enable = true;

  nix = {
    settings = {
      experimental-features = "nix-command flakes";
      auto-optimise-store = true;
      trusted-users = [
        "root"
        "@wheel"
      ];
    };

    optimise.automatic = true;
    optimise.dates = [ "03:45" ];

    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 1d";
    };

    extraOptions = ''
      min-free = ${toString (100 * 1024 * 1024)}
      max-free = ${toString (2 * 1024 * 1024 * 1024)}
    '';
  };
}
